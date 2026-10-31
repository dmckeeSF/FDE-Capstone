import { LightningElement } from 'lwc';
import getContactId from '@salesforce/apex/GetCurrentUserContactId.getContactId';

export default class AriaIdentityInjector extends LightningElement {
    connectedCallback() {
        getContactId()
            .then(contactId => {
                if (!contactId) return;
                const inject = () => {
                    if (window.embeddedservice_bootstrap && window.embeddedservice_bootstrap.prechatAPI) {
                        window.embeddedservice_bootstrap.prechatAPI.setHiddenPrechatFields({ ContactId: contactId });
                    } else {
                        window.addEventListener('onEmbeddedMessagingReady', () => {
                            window.embeddedservice_bootstrap.prechatAPI.setHiddenPrechatFields({ ContactId: contactId });
                        }, { once: true });
                    }
                };
                inject();
            })
            .catch(() => {});
    }
}
