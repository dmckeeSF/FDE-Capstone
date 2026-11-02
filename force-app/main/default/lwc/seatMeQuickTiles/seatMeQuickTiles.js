import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ID from '@salesforce/user/Id';
import CONTACT_ID from '@salesforce/schema/User.ContactId';

export default class SeatMeQuickTiles extends NavigationMixin(LightningElement) {

    @wire(getRecord, { recordId: ID, fields: [CONTACT_ID] })
    currentUser;

    get contactId() {
        return getFieldValue(this.currentUser.data, CONTACT_ID);
    }

    get tiles() {
        return [
            {
                id: 'restaurants',
                icon: '🍽',
                label: 'Find Restaurants',
                desc: 'Browse and explore dining options',
                action: 'restaurants'
            },
            {
                id: 'reservations',
                icon: '📅',
                label: 'My Reservations',
                desc: 'View, modify, or cancel bookings',
                action: 'reservations'
            },
            {
                id: 'policies',
                icon: '❓',
                label: 'Policies & FAQs',
                desc: 'Cancellation rules and platform help',
                action: 'policies'
            },
            {
                id: 'support',
                icon: '🙋',
                label: 'Get Help',
                desc: 'Chat with Aria or reach our team',
                action: 'support'
            }
        ];
    }

    handleKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            this.handleTileClick(event);
        }
    }

    handleTileClick(event) {
        const action = event.currentTarget.dataset.action;
        switch (action) {
            case 'restaurants':
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: { objectApiName: 'Account', actionName: 'list' }
                });
                break;
            case 'reservations':
                if (this.contactId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: { recordId: this.contactId, actionName: 'view' }
                    });
                }
                break;
            case 'policies':
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: { name: 'Top_Articles__c' }
                });
                break;
            case 'support':
                try {
                    window.embeddedservice_bootstrap.utilAPI.launchChat();
                } catch (e) {
                    try { window.embedded_svc.onHelpButtonClick(); } catch (e2) { /* noop */ }
                }
                break;
            default:
                break;
        }
    }

    // Bind click handler per tile via event delegation on the ul
    connectedCallback() {
        // Event delegation handled via data-action on li elements
    }
}
