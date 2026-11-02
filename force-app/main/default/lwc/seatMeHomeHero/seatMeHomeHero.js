import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ID from '@salesforce/user/Id';
import CONTACT_ID from '@salesforce/schema/User.ContactId';
import logoUrl from '@salesforce/resourceUrl/SeatMe_LogoWhite';
import heroUrl from '@salesforce/resourceUrl/SeatMe_HeroBackground';

export default class SeatMeHomeHero extends NavigationMixin(LightningElement) {
    logoUrl = logoUrl;
    heroUrl = heroUrl;

    @wire(getRecord, { recordId: ID, fields: [CONTACT_ID] })
    currentUser;

    get contactId() {
        return getFieldValue(this.currentUser.data, CONTACT_ID);
    }

    handleChatClick() {
        try {
            window.embeddedservice_bootstrap.utilAPI.launchChat();
        } catch (e) {
            try {
                window.embedded_svc.onHelpButtonClick();
            } catch (e2) { /* widget not ready */ }
        }
    }

    handleReservationsClick() {
        if (this.contactId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.contactId,
                    actionName: 'view'
                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: { name: 'Home' }
            });
        }
    }
}
