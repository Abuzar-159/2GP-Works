#!/usr/bin/env node

// Must wrap script in async function to use await
(async () => {

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const readline = require("readline");

const DEV_BRANCH = "dev-abuzar";
const DEPLOY_BRANCH = "deploy2gp";

const ALLOWED_ORG_DOMAIN = "https://aqxolt-base-dev-ed.develop.my.salesforce.com";
const TARGET_ORG_ALIAS = "2GP";

// 🔥 Toggle auto commit ON/OFF
const autoCommit = false;   // if true → skip asking for commit msg

const DIFF_FILE = "deploy-file-list.txt";

function run(cmd, allowError = false) {
  try {
    return execSync(cmd, { stdio: "pipe" }).toString().trim();
  } catch (e) {
    if (allowError) return "";
    console.error(`❌ ERROR executing: ${cmd}\n${e.stderr?.toString()}`);
    if (cmd.includes(`git merge --no-edit ${DEV_BRANCH}`)) {
      console.log(`
        🚨 Manual action required!
        You now have merge conflicts in branch '${DEPLOY_BRANCH}'.

        Please do the following:
          Fix conflicts in your editor
          and then run:
          git commit --no-edit
          git push origin ${DEPLOY_BRANCH}
          git checkout ${DEV_BRANCH}
          Re-run this script to continue deployment

        The script will stop now.
          `);
    }
    process.exit(1);
  }
}

// ----------------------- PRECHECK -----------------------
console.log("🔍 Checking if inside a Git repo...");
run("git rev-parse --is-inside-work-tree");
const current = run("git rev-parse --abbrev-ref HEAD");
if (current !== DEV_BRANCH) {
  console.error(`❌ Must run on '${DEV_BRANCH}', current: '${current}'`);
  run(`git checkout ${DEV_BRANCH}`);
  console.log('🔀 Switched to dev branch. Please re-run the script.');
  process.exit(1);
}

// -------------------- COMMIT CHANGES --------------------
console.log("📝 Checking for local changes...");
const changes = run("git status --porcelain");

if (changes) {
  const dateMsg = new Date().toLocaleString("en-IN");
  let finalCommitMsg = `by ${DEV_BRANCH} on ${dateMsg}`;

  if (!autoCommit) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    await new Promise(resolve => {
      rl.question("💬 Enter commit message (Press Enter to skip): ", msg => {
        if (msg.trim()) {
          finalCommitMsg = `${msg} by ${DEV_BRANCH} on ${dateMsg}`;
        }
        rl.close();
        resolve();
      });
    });
  }

  console.log(`📝 Committing with message: "${finalCommitMsg}"`);
  run("git add .");
  run(`git commit -m "${finalCommitMsg}"`);
}

run(`git push origin ${DEV_BRANCH}`);

// ---------------- RUN DIFF BEFORE MERGE ------------------
run("git fetch --all");

const diffCmd = `git diff --name-only origin/${DEPLOY_BRANCH}...origin/${DEV_BRANCH}`;
let diffRaw = run(diffCmd, true);

console.log("📌 RAW changed files BEFORE FILTER:");
console.log(diffRaw || "⚠️ EMPTY diff");

const rawFiles = diffRaw.split("\n").filter(f => f);

// -------- IMPROVED METADATA FILTERING --------
function getMetadataFolder(filePath) {
  if (filePath.startsWith("force-app/") || filePath.startsWith("main/")) {
    const parts = filePath.split("/");

    if (parts.includes("lwc")) {
      const idx = parts.indexOf("lwc");
      return parts.slice(0, idx + 2).join("/");
    }

    if (filePath.endsWith(".cls") || filePath.endsWith(".cls-meta.xml")) {
      return path.dirname(filePath);
    }

    if (parts.includes("aura")) {
      const idx = parts.indexOf("aura");
      return parts.slice(0, idx + 2).join("/");
    }

    if (parts.includes("objects")) {
      const idx = parts.indexOf("objects");
      return parts.slice(0, idx + 3).join("/");
    }

    return path.dirname(filePath);
  }

  return null;
}

const metadataFolders = Array.from(
  new Set(
    rawFiles
      .map(getMetadataFolder)
      .filter(Boolean)
  )
);

console.log("🎯 Filtered metadata folders:", metadataFolders);

fs.writeFileSync(DIFF_FILE, metadataFolders.join("\n"));

// ------------------------- MERGE -------------------------
console.log(`🔀 Switching to ${DEPLOY_BRANCH}...`);
run(`git checkout ${DEPLOY_BRANCH}`);

console.log(`⬇️ Pulling latest ${DEPLOY_BRANCH}...`);
run(`git pull origin ${DEPLOY_BRANCH}`);

console.log(`🔀 Merging ${DEV_BRANCH} → ${DEPLOY_BRANCH}`);
try {
  run(`git merge --no-edit ${DEV_BRANCH}`);
} catch {
  console.error("❌ Merge conflict! Solve and re-run.");
  console.log(`
    🚨 Manual action required!
    You now have merge conflicts in branch '${DEPLOY_BRANCH}'.

    Please do the following:
      Fix conflicts in your editor
      and then run:

      git add .
      git commit -m "Manual merge commit after resolving conflicts from ${DEV_BRANCH}"
      git push origin ${DEPLOY_BRANCH}
      git checkout ${DEV_BRANCH}


      Re-run this script to continue deployment

    The script will stop now.
      `);
  process.exit(1);
}

run(`git push origin ${DEPLOY_BRANCH}`);

console.log(`🔁 Switching back to ${DEV_BRANCH}...`);
run(`git checkout ${DEV_BRANCH}`);

// ----------------------- DEPLOY --------------------------
let deployFiles = fs.readFileSync(DIFF_FILE, "utf8")
  .split("\n")
  .filter(f => f);

if (deployFiles.length === 0) {
  console.log("⚠️ No metadata to deploy.");
  process.exit(0);
}

console.log("🚀 Deploying changed metadata...");

// Build deploy command
const deployCmd =
  `sf project deploy start -o ${TARGET_ORG_ALIAS} --json ` +
  deployFiles.map(f => `--source-dir ${f}`).join(" ");

let deployResultRaw = "";
let deployJson = null;

try {
  deployResultRaw = run(deployCmd, true);   // allow errors, don’t exit
  fs.writeFileSync("deploy-log.txt", deployResultRaw);

  try {
    deployJson = JSON.parse(deployResultRaw);
  } catch (e) {
    console.error("❌ Failed to parse deploy JSON. Raw output:\n", deployResultRaw);
  }

  // If deploy returned errors → HANDLE
  if (!deployJson || deployJson.status !== 0) {
    console.error("\n❌ DEPLOY FAILED!");

    // Show human-readable errors
    if (deployJson?.result?.details?.componentFailures) {
      const fails = deployJson.result.details.componentFailures;
      console.log("\n=== Deploy Errors ===");

      (Array.isArray(fails) ? fails : [fails]).forEach(f => {
        console.log(`\nFILE: ${f.fileName}`);
        console.log(`ERROR: ${f.problem}`);
      });
    } else {
      console.log("\nRaw deployment error output:\n", deployResultRaw);
    }

    // 🔥 AUTO-ROLLBACK MERGE COMMIT
    console.log("\n🔁 Rolling back merge commit on deploy2gp...");

    // Find last merge commit made by this script
    const mergeHash = run(`git log -1 --pretty=format:%H origin/${DEPLOY_BRANCH}`);
    const devHash = run(`git log -1 --pretty=format:%H origin/${DEV_BRANCH}`);

    run(`git checkout ${DEPLOY_BRANCH}`);
    run(`git revert -m 1 ${mergeHash} --no-edit`);
    run(`git push origin ${DEPLOY_BRANCH}`);

    console.log("\n🧹 Merge reverted successfully. Your broken code was NOT pushed.");
    run(`git checkout ${DEV_BRANCH}`);
    // run(`git revert -m 1 ${devHash} --no-edit`);
    process.exit(1);
  }

} catch (err) {
  console.error("❌ Unexpected deployment error:", err);
  process.exit(1);
}

// ---------------- DEPLOY SUCCESS OUTPUT ------------------
console.log("🎉 DEPLOY SUCCESS!");

if (deployJson?.result?.files) {
  console.table(
    deployJson.result.files.map(f => ({
      File: f.fullName,
      Type: f.type,
      Status: f.state
    }))
  );
}

console.log("🎉 DONE!");


})();  // end async wrapper
