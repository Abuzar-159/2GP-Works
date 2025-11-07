import { LightningElement, wire,api ,track} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import bookFreightview from '@salesforce/apex/freightView.bookFreightview';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
 import getShipmentDocs from '@salesforce/apex/freightView.getShipmentDocs';
export default class ServiceList extends  NavigationMixin(LightningElement) {

    
    @api fromAddress;
    @api toAddress;
    @api fromContact;
    @api toContact;
    @api packageList;
    @api quotes;
    @api shipment;
    @api credentials;
    @track isSuccessPageOpen = false; 
    @track groupedQuotes = [];     // UI-ready groups
    @track expanded = new Set();   // which parent indices are expanded
    @track selectedQuoteId; 
    @track selectedService = {
        quoteId: null,
        carrier: '—',
        service: '—',
        amount: null,
        currencyCode: 'USD',
        amountFormatted: '—'
        };
    @track bookingResult;   
    @track isLoading = false;
      docIds = {}; 
    connectedCallback() {
        console.log('quotes ',JSON.stringify(this.quotes));
        console.log('shipment in shippingRates : ',JSON.stringify(this.shipment));
         this.buildGroups();
    }
 
 buildGroups() {
    if (!Array.isArray(this.quotes) || this.quotes.length === 0) {
        this.groupedQuotes = [];
        return;
    }

    // ---------- local helpers (scoped to this method) ----------
    const rateTitleCase = (s) =>
        !s ? '' : String(s).toLowerCase().replace(/(^\w)|(\s+\w)/g, m => m.toUpperCase());

    const deriveRateFlavor = (q) => {
        // 1) strongest: pricingMethod
        const pm = (q.pricingMethod || '').toString().toLowerCase();
        if (pm) {
            const map = { contracted: 'Contracted', dynamic: 'Dynamic', spot: 'Spot', capacity: 'Capacity' };
            return map[pm] || rateTitleCase(pm);
        }
        // 2) fallback: serviceDescription
        const sd = (q.serviceDescription || '').toString().toLowerCase();
        if (/spot/.test(sd) && /volume/.test(sd)) return 'Spot Volume';
        if (/spot/.test(sd)) return 'Spot';
        if (/volume/.test(sd)) return 'Volume';
        if (/capacity/.test(sd)) return 'Capacity';
        if (/dynamic/.test(sd)) return 'Dynamic';
        if (/guarantee/.test(sd)) return 'Guaranteed';
        // 3) weaker: pricingType
        const pt = (q.pricingType || '').toString().toLowerCase();
        if (pt === 'tariff') return 'Contracted';
        return '';
    };

    const transitSnippet = (min, max, timeMins) => {
        const isNum = (n) => Number.isFinite(n);
        if (isNum(min) || isNum(max)) {
            if (isNum(min) && isNum(max)) {
                if (min === max) return `${min} ${min === 1 ? 'day' : 'days'}`;
                return `${min}–${max} days`;
            }
            const v = isNum(min) ? min : max;
            return `${v} ${v === 1 ? 'day' : 'days'}`;
        }
        if (isNum(timeMins)) {
            const d = Math.max(1, Math.round(timeMins / 1440));
            return `${d} ${d === 1 ? 'day' : 'days'}`;
        }
        return '';
    };

    const fin = (n) => Number.isFinite(n);

    // ---------- normalize & enrich each quote ----------
    const enriched = this.quotes.map(q => {
        const currency = (q.currencyCode || q.currency || 'USD').toString().toUpperCase();
        const amount = this.safeNumber(q.amount);
        const mode = (q.mode || q.equipmentType || 'ltl').toString().toUpperCase();
        const provider = (q.providerName || '').trim();
        const carrier = (q.assetCarrierName || q.providerName || 'Unknown Carrier').trim();
        const flavor = deriveRateFlavor(q);
        const via = provider && provider !== carrier ? `via ${provider}` : '';
        const transit = transitSnippet(
            q.transitDaysMin != null ? q.transitDaysMin : null,
            q.transitDaysMax != null ? q.transitDaysMax : null,
            fin(q.time) ? q.time : null
        );

        // build helper line with only available parts
        const parts = [mode, flavor ? `(${flavor})` : '', via, transit].filter(Boolean);
        const helperLine = parts.join(' ');

        const isGuaranteed =
            /guarantee|guaranteed/i.test(q.serviceId || '') ||
            /guarantee|guaranteed/i.test(q.serviceDescription || '');
        const isInterline = q.interline === true;

        return {
            ...q,
            carrierDisplay: carrier,
            currencyCode: currency,
            amount,
            amountFormatted: this.fmtCurrency(amount, currency),
            helperLine,
            isGuaranteed,
            isInterline,
            transitMin: (q.transitDaysMin != null) ? q.transitDaysMin : null,
            transitMax: (q.transitDaysMax != null) ? q.transitDaysMax : null
        };
    });

    // ---------- global cheapest & fastest (for badges/sorting) ----------
    const allAmts = enriched.map(e => e.amount).filter(fin);
    const globalMinAmount = allAmts.length ? Math.min(...allAmts) : null;

    // prefer "time" (minutes) else transitMin (days → minutes)
    const allTimes = enriched.map(e =>
        fin(e.time) ? e.time : (fin(e.transitMin) ? e.transitMin * 1440 : Infinity)
    );

    // ---------- group by carrier ----------
    const groupsMap = new Map();
    for (const q of enriched) {
        if (!groupsMap.has(q.carrierDisplay)) groupsMap.set(q.carrierDisplay, []);
        groupsMap.get(q.carrierDisplay).push(q);
    }

    // ---------- assemble UI groups ----------
    const groups = [];
    let idx = 0;

    groupsMap.forEach((list, carrier) => {
        // children sorted by price asc
        list.sort((a, b) => (a.amount ?? Infinity) - (b.amount ?? Infinity));

        const child = list.map((q, ci) => ({
            ...q,
            childCardClass: this.childCardClass(q.quoteId, ci)
        }));

        const amounts = child.map(c => c.amount).filter(fin);
        const grpMin = amounts.length ? Math.min(...amounts) : null;
        const currency = child[0]?.currencyCode || 'USD';

        const minTransit = this.minDefined(child.map(c => c.transitMin));
        const maxTransit = this.maxDefined(child.map(c => c.transitMax));
        const transitDisplay = this.transitText(minTransit, maxTransit);

        const showMostAffordableTag = (globalMinAmount != null) && (grpMin === globalMinAmount);
        const showReliableTag = child.some(c => c.isInterline === false);

        const expanded = this.expanded.has(idx);

        groups.push({
            key: `${carrier}-${idx}`,
            displayName: carrier,
            optionsCount: child.length,
            quotes: child,
            minAmountFormatted: grpMin != null ? this.fmtCurrency(grpMin, currency) : this.fmtCurrency(0, currency),
            transitDisplay,
            showMostAffordableTag,
            showReliableTag,
            childContainerClass: `child-service-container${expanded ? '' : ' slds-is-collapsed'}`
        });

        idx += 1;
    });

    // sort groups by starting cost (cheapest first)
    groups.sort((a, b) => {
        // quick numeric scrape from formatted value
        const toNum = (s) => {
            if (!s) return Infinity;
            const n = Number(String(s).replace(/[^\d.,-]/g, '').replace(/,/g, ''));
            return Number.isFinite(n) ? n : Infinity;
        };
        return toNum(a.minAmountFormatted) - toNum(b.minAmountFormatted);
    });

    this.groupedQuotes = groups;
}


    // ===== UI Events =====
    toggleChildServices = (evt) => {
        const i = Number(evt.currentTarget?.dataset?.index);
        if (Number.isNaN(i)) return;

        if (this.expanded.has(i)) this.expanded.delete(i);
        else this.expanded.add(i);

        // reapply collapsed class only
        this.groupedQuotes = this.groupedQuotes.map((g, idx) => ({
            ...g,
            childContainerClass: `child-service-container${this.expanded.has(idx) ? '' : ' slds-is-collapsed'}`
        }));
    };

   handleQuoteSelect = (event) => {
  const selectedQuoteId = event.currentTarget.dataset.id;
  this.selectedQuoteId = selectedQuoteId;

  // refresh visual
  this.groupedQuotes = this.groupedQuotes.map(g => ({
    ...g,
    quotes: g.quotes.map((q, ci) => ({
      ...q,
      childCardClass: this.childCardClass(q.quoteId, ci)
    }))
  }));

  // find full quote object
  let selected = null;
  for (const g of this.groupedQuotes) {
    selected = g.quotes.find(q => q.quoteId === selectedQuoteId);
    if (selected) break;
  }

  // 🔹 Update the selected summary
  const carrier =
    selected?.carrierDisplay ||
    selected?.assetCarrierName ||
    selected?.providerName ||
    '—';

  const service =
    selected?.serviceDescription ||
    '—';

  const currency = (selected?.currencyCode || selected?.currency || 'USD').toUpperCase();
  const amount = this.safeNumber(selected?.amount);
  const amountFormatted = Number.isFinite(amount)
    ? this.fmtCurrency(amount, currency)
    : '—';

  this.selectedService = {
    quoteId: selected?.quoteId || null,
    carrier,
    service,
    amount,
    currencyCode: currency,
    amountFormatted
  };

  // 🔹 Emit richer payload for parent usage
  this.dispatchEvent(new CustomEvent('quoteselect', {
    detail: {
      quoteId: selectedQuoteId,
      quote: selected,
      summary: { ...this.selectedService }, // easy to consume
      bookUrl: selected?.shipmentBookPageUrl || null
    }
  }));
};


// helpers (add this one)
parseCurrency(str) {
    if (!str) return NaN;
    // quick numeric scrape: keep digits, dot, and comma
    const num = Number(String(str).replace(/[^\d.,-]/g, '').replace(/,/g, ''));
    return Number.isFinite(num) ? num : NaN;
}

    // ===== Helpers =====
    childCardClass(quoteId, childIndex) {
        // Keep your exact base classes; match your sample spacing:
        // first child -> top_small; subsequent -> top_none
        const topClass = childIndex === 0 ? 'slds-m-top_small' : 'slds-m-top_none';
        const base = `service-card child-card slds-p-vertical_small slds-p-horizontal_medium ${topClass} slds-m-bottom_small`;
        return quoteId === this.selectedQuoteId ? `${base} selected-service-card` : base;
    }

    transitText(min, max) {
        if (min == null && max == null) return 'Business Days';
        if (min != null && max != null) {
            if (min === max) return `${min} Business Days`;
            return `${min}–${max} Business Days`;
        }
        const v = (min ?? max);
        return `${v} Business Days`;
    }

    safeNumber(n) {
        const num = typeof n === 'string' ? Number(n) : n;
        return Number.isFinite(num) ? num : NaN;
    }

    fmtCurrency(amount, currency) {
        try {
            return new Intl.NumberFormat(undefined, { style: 'currency', currency: (currency || 'USD').toUpperCase() })
                .format(amount ?? 0);
        } catch {
            return `$${(amount ?? 0).toFixed(2)}`;
        }
    }

    minDefined(arr) {
        const vals = arr.filter(v => v !== null && v !== undefined);
        return vals.length ? Math.min(...vals) : null;
    }

    maxDefined(arr) {
        const vals = arr.filter(v => v !== null && v !== undefined);
        return vals.length ? Math.max(...vals) : null;
    }

    handleGoBack() {
           this.isSuccessPageOpen = false;
            const backEvent = new CustomEvent('backtoparent');
           this.dispatchEvent(backEvent);
           console.log('event triggered');
    }
  
    // handleReadyToShip() {

    //     this.isSuccessPageOpen = true; 

    // }
    

     handleBackToForm() {
        console.log('Back to Form button clicked');
        const backEvent = new CustomEvent('backtoparent');
        this.dispatchEvent(backEvent);
        console.log('event triggered');
        
    }
   async handleReadyToShip() {
    try {
        if (!this.selectedService?.quoteId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Select a Service',
                    message: 'Please select a quote to book before proceeding.',
                    variant: 'warning'
                })
            );
            return;
        }
        console.log('shipment in handleReadyToShip : ',JSON.stringify(this.shipment));
        console.log('shipment in this.shipment.shipmentID__c : ',this.shipment.shipmentID__c);
        if (!this.shipment || !this.shipment.shipmentID__c) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Shipment Details',
                    message: 'Shipment record or Freightview Shipment ID is missing.',
                    variant: 'error'
                })
            );
            return;
        }

        // Build JSON strings
        const shipmentJSON = JSON.stringify(this.shipment);
        const credentialsJSON = JSON.stringify(this.credentials);
        console.log('shipment id : ',shipmentJSON.Id);
        this.isLoading = true;
        // ✅ Correctly pass the JSON variables
        const result = await bookFreightview({
            shipmentJson: shipmentJSON,
            quoteId: this.selectedService.quoteId,
            schedulePickup: true,
            myConsVar: credentialsJSON
        });

        console.log('Booking Result:', JSON.stringify(result));
        console.log('result : ',result.success);
        if (!result || !result.success) {
            throw new Error(result?.message || 'Booking failed.');
        }
        //if(result.success) {this.isSuccessPageOpen = true;}
        this.isSuccessPageOpen = !!result?.success;
        this.bookingResult = result;
        this.shipment = result.ShipDetails
        this.shipment.shipmentUrl = '/lightning/r/Shipment__c/'+ this.shipment.Id+'/view';
        // Optional UI updates
        this.selectedService.carrier = result.carrier || this.selectedService.carrier;
        this.selectedService.service = result.service || this.selectedService.service;
        if (result.amount) {
            this.selectedService.amount = result.amount;
            this.selectedService.amountFormatted = this.formatCurrency(result.amount, result.currencyCode);
            
        }
        // this.docIds = result.docByType || this.deriveDocMap(result.contentDocumentIds, result.contentTitles);
        // console.log('docids ',JSON.stringify(this.docIds));
        try {
                await this.fetchDocsForShipment();
            } catch (docError) {
                console.warn('Could not fetch shipment docs:', docError);
                this.docIds = {}; // fallback to empty
            }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Shipment Booked',
                message: `Status: ${result.status || 'Confirmed'} • Tracking: ${result.trackingNumber || '—'}`,
                variant: 'success'
            })
        );

        this.dispatchEvent(new CustomEvent('booked', { detail: result }));

    } catch (e) {
        console.error('Error booking shipment:', e);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Booking Error',
                message: e.message,
                variant: 'error'
            })
        );
    }finally {
    // ✅ Always stop the spinner
    this.isLoading = false;
  }
}
  formatCurrency(amount, currencyCode) {
        const n = Number(amount);
        if (Number.isNaN(n)) return '';
        const cur = currencyCode || DEFAULT_CURRENCY || 'USD';
        try {
            return new Intl.NumberFormat(LOCALE, {
                style: 'currency',
                currency: cur,
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            }).format(n);
        } catch (err) {
            // Fallback if currency code is invalid
            return n.toFixed(2);
        }
    }
   deriveDocMap(ids, titles) {
    const map = {};
    if (!ids || !titles) return map;
    for (let i = 0; i < ids.length; i++) {
      const t = (titles[i] || '').toLowerCase();
      if (t.includes('bol')) map['bol'] = ids[i];
      if (t.includes('label')) map['label'] = ids[i];
    }
    return map;
  }


  openPreview(event) {
    const type = event.currentTarget.dataset.type; // 'bol' or 'label'
    const contentDocumentId = this.docIds?.[type];
    if (!contentDocumentId) {
      this.showToast('File Not Found', `No ${type.toUpperCase()} document found.`, 'warning');
      return;
    }
    this.openPreviewById(contentDocumentId);
  }

 openPreviewById(contentDocumentId) {
    console.log('Navigating to ContentDocumentId:', contentDocumentId);
    this[NavigationMixin.Navigate]({
        type: 'standard__namedPage',
        attributes: { pageName: 'filePreview' },
        state: { selectedRecordId: contentDocumentId }
    });
}

showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({ title, message, variant })
    );
  }
async fetchDocsForShipment() {
    if (!this.shipment?.Id) return;
    try {
        this.isLoading = true;
        const docs = await getShipmentDocs({ shipmentId: this.shipment.Id });
        this.docIds = docs;
        console.log('Fetched docIds:', JSON.stringify(this.docIds));
    } catch (error) {
        console.error('Error fetching shipment docs:', error);
    } finally {
        this.isLoading = false;
    }
}
}