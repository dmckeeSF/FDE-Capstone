import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFeaturedRestaurants from '@salesforce/apex/SeatMeFeaturedRestaurantsController.getFeaturedRestaurants';

export default class SeatMeFeaturedRestaurants extends NavigationMixin(LightningElement) {
    restaurants = [];
    isLoading = true;
    placeholders = [1, 2, 3];

    @wire(getFeaturedRestaurants)
    wiredRestaurants({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.restaurants = data.map(r => ({
                ...r,
                bookLabel: `Book a table at ${r.name}`
            }));
        } else if (error) {
            this.restaurants = [];
        }
    }

    get hasRestaurants() {
        return !this.isLoading && this.restaurants.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && this.restaurants.length === 0;
    }

    handleKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            this.handleCardClick(event);
        }
    }

    handleCardClick(event) {
        const id = event.currentTarget.dataset.id;
        if (id) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: id, actionName: 'view' }
            });
        }
    }
}
