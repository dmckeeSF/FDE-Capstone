import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const TZ_LABELS = {
    'America/Los_Angeles': 'PT',
    'America/Denver':      'MT',
    'America/Chicago':     'CT',
    'America/New_York':    'ET',
    'America/Phoenix':     'MST',
    'Pacific/Honolulu':    'HT',
};
function tzLabel(ianaZone) {
    return TZ_LABELS[ianaZone] || ianaZone || '';
}
import getRestaurants      from '@salesforce/apex/ReservationController.getRestaurants';
import getAvailableSlots   from '@salesforce/apex/ReservationController.getAvailableSlots';
import createReservation   from '@salesforce/apex/ReservationController.createReservation';
import getMyReservations   from '@salesforce/apex/ReservationController.getMyReservations';
import cancelReservation   from '@salesforce/apex/ReservationController.cancelReservation';

const MIN_PARTY = 1;
const MAX_PARTY = 8;

export default class AriaDiningBooking extends LightningElement {

    // ── step: 1 | 2 | 3 | 4 ─────────────────────────────────────────────────
    @track step = 1;

    // ── restaurant list (from wire) ──────────────────────────────────────────
    @track restaurants = [];

    // ── selections ───────────────────────────────────────────────────────────
    @track selectedRestaurantId   = null;
    @track selectedRestaurantName = '';
    @track selectedRestaurantTz   = '';
    @track reservationDate        = '';
    @track partySize              = 2;
    @track selectedTime           = '';
    @track specialRequests        = '';

    // ── slots ────────────────────────────────────────────────────────────────
    @track timeSlots     = [];
    @track loadingSlots  = false;

    // ── confirmation ─────────────────────────────────────────────────────────
    @track bookingReference  = '';
    @track confirmedRestaurant = '';
    @track confirmedDate     = '';
    @track confirmedTime     = '';
    @track confirmedParty    = 0;

    // ── my reservations ──────────────────────────────────────────────────────
    @track upcomingReservations = [];

    // ── misc ─────────────────────────────────────────────────────────────────
    @track isBooking     = false;
    @track errorMessage  = '';

    // ─── Wire: restaurants ────────────────────────────────────────────────────
    @wire(getRestaurants)
    wiredRestaurants({ data, error }) {
        if (data) {
            this.restaurants = data.map(r => ({ ...r, isSelected: false }));
        } else if (error) {
            this.errorMessage = this._extractError(error);
        }
    }

    // ─── Wire: upcoming reservations ─────────────────────────────────────────
    @wire(getMyReservations)
    wiredUpcoming({ data, error }) {
        if (data) {
            this.upcomingReservations = data.map(r => ({
                ...r,
                tzShort: tzLabel(r.timeZone)
            }));
        }
        // Silence errors — guest users won't have a ContactId
    }

    // ─── Step getters ─────────────────────────────────────────────────────────
    get isStep1() { return this.step === 1; }
    get isStep2() { return this.step === 2; }
    get isStep3() { return this.step === 3; }
    get isStep4() { return this.step === 4; }

    get stepClass1() { return `step-indicator${this.step >= 1 ? ' active' : ''}${this.step > 1 ? ' done' : ''}`; }
    get stepClass2() { return `step-indicator${this.step >= 2 ? ' active' : ''}${this.step > 2 ? ' done' : ''}`; }
    get stepClass3() { return `step-indicator${this.step >= 3 ? ' active' : ''}${this.step > 3 ? ' done' : ''}`; }

    // ─── Restaurant card CSS ──────────────────────────────────────────────────
    get restaurantCardClass() { return 'restaurant-card'; }

    // ─── Derived booleans ────────────────────────────────────────────────────
    get noRestaurantSelected()   { return !this.selectedRestaurantId; }
    get partyAtMin()             { return this.partySize <= MIN_PARTY; }
    get partyAtMax()             { return this.partySize >= MAX_PARTY; }
    get hasSlots()               { return !this.loadingSlots && this.timeSlots.length > 0; }
    get noSlots()                { return !this.loadingSlots && this.reservationDate && this.timeSlots.length === 0; }
    get cannotProceedToStep3()   { return !this.selectedTime; }
    get hasUpcomingReservations(){ return this.upcomingReservations.length > 0; }
    get minDate() {
        const d = new Date();
        d.setDate(d.getDate() + 1);
        return d.toISOString().split('T')[0];
    }

    // ─── Restaurant selection ────────────────────────────────────────────────
    handleRestaurantSelect(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedRestaurantId = id;
        const r = this.restaurants.find(x => x.id === id);
        this.selectedRestaurantName = r ? r.name : '';
        this.selectedRestaurantTz   = r ? tzLabel(r.timeZone) : '';
        this.restaurants = this.restaurants.map(x => ({
            ...x,
            isSelected: x.id === id,
            cssClass: `restaurant-card${x.id === id ? ' selected' : ''}`
        }));
    }

    // ─── Step navigation ─────────────────────────────────────────────────────
    goStep1() { this.step = 1; this.errorMessage = ''; }

    goStep2() {
        if (!this.selectedRestaurantId) return;
        this.step = 2;
        this.errorMessage = '';
        if (this.reservationDate) this._loadSlots();
    }

    goStep3() {
        if (!this.selectedTime) return;
        this.step = 3;
        this.errorMessage = '';
    }

    // ─── Date & party ────────────────────────────────────────────────────────
    handleDateChange(event) {
        this.reservationDate = event.target.value;
        this.selectedTime = '';
        this.timeSlots = [];
        if (this.reservationDate) this._loadSlots();
    }

    decrementParty() {
        if (this.partySize > MIN_PARTY) {
            this.partySize -= 1;
            this.selectedTime = '';
            if (this.reservationDate) this._loadSlots();
        }
    }

    incrementParty() {
        if (this.partySize < MAX_PARTY) {
            this.partySize += 1;
            this.selectedTime = '';
            if (this.reservationDate) this._loadSlots();
        }
    }

    // ─── Slot selection ──────────────────────────────────────────────────────
    handleSlotSelect(event) {
        const time = event.currentTarget.dataset.time;
        this.selectedTime = time;
        this.timeSlots = this.timeSlots.map(s => ({
            ...s,
            cssClass: `time-slot-btn${s.slotTime === time ? ' selected' : ''}`
        }));
    }

    // ─── Special requests ────────────────────────────────────────────────────
    handleSpecialRequests(event) {
        this.specialRequests = event.target.value;
    }

    // ─── Book ────────────────────────────────────────────────────────────────
    async handleBook() {
        this.isBooking = true;
        this.errorMessage = '';
        try {
            const result = await createReservation({
                restaurantName:   this.selectedRestaurantName,
                reservationDate:  this.reservationDate,
                reservationTime:  this.selectedTime,
                partySize:        this.partySize,
                specialRequests:  this.specialRequests
            });

            if (result.isSuccess) {
                this.bookingReference    = result.bookingReference;
                this.confirmedRestaurant = result.restaurantName;
                this.confirmedDate       = result.reservationDate;
                this.confirmedTime       = result.reservationTime;
                this.confirmedParty      = result.partySize;
                this.step = 4;
            } else {
                this.errorMessage = result.message;
            }
        } catch (e) {
            this.errorMessage = this._extractError(e);
        } finally {
            this.isBooking = false;
        }
    }

    // ─── Cancel ──────────────────────────────────────────────────────────────
    async handleCancelReservation(event) {
        const ref = event.currentTarget.dataset.ref;
        try {
            await cancelReservation({ bookingReference: ref, reason: 'Cancelled by diner' });
            this.upcomingReservations = this.upcomingReservations.filter(r => r.bookingReference !== ref);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Reservation Cancelled',
                message: `${ref} has been cancelled.`,
                variant: 'success'
            }));
        } catch (e) {
            this.errorMessage = this._extractError(e);
        }
    }

    // ─── Reset ───────────────────────────────────────────────────────────────
    resetBooking() {
        this.step = 1;
        this.selectedRestaurantId   = null;
        this.selectedRestaurantName = '';
        this.selectedRestaurantTz   = '';
        this.reservationDate        = '';
        this.partySize              = 2;
        this.selectedTime           = '';
        this.specialRequests        = '';
        this.timeSlots              = [];
        this.bookingReference       = '';
        this.errorMessage           = '';
        this.restaurants = this.restaurants.map(r => ({ ...r, isSelected: false }));
    }

    // ─── Slot loader ─────────────────────────────────────────────────────────
    async _loadSlots() {
        this.loadingSlots = true;
        this.timeSlots = [];
        try {
            const slots = await getAvailableSlots({
                restaurantName:  this.selectedRestaurantName,
                reservationDate: this.reservationDate,
                partySize:       this.partySize
            });
            this.timeSlots = slots.map(s => ({
                ...s,
                cssClass: `time-slot-btn${s.slotTime === this.selectedTime ? ' selected' : ''}`
            }));
        } catch (e) {
            this.errorMessage = this._extractError(e);
        } finally {
            this.loadingSlots = false;
        }
    }

    // ─── Error helper ────────────────────────────────────────────────────────
    _extractError(e) {
        if (e && e.body && e.body.message) return e.body.message;
        if (e && e.message) return e.message;
        return 'An unexpected error occurred.';
    }
}
