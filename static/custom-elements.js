class SortableList extends HTMLElement {
  constructor() {
    super();
    this.sortableInstance = null;
  }

  connectedCallback() {
    // Initialize Sortable when the element is added to the DOM
    this.sortableInstance = Sortable.create(this, {
      handle: '.sortable-handle',
      animation: 150,
      // Enable touch support
      touchStartThreshold: 3,
      // Dispatch custom events when items are reordered
      onEnd: (evt) => {
        const detail = {
          oldIndex: evt.oldIndex,
          newIndex: evt.newIndex,
          // Include item IDs for more reliable tracking
          itemId: evt.item.getAttribute('data-id')
        };
        
        this.dispatchEvent(new CustomEvent('item-reordered', { 
          detail,
          bubbles: true
        }));
      }
    });
  }

  disconnectedCallback() {
    // Clean up when the element is removed
    if (this.sortableInstance) {
      this.sortableInstance.destroy();
      this.sortableInstance = null;
    }
  }

  // Method to programmatically update order
  updateOrder(newOrderIds) {
    // First check if we need to do anything
    const currentIds = Array.from(this.children).map(el => el.getAttribute('data-id'));
    if (JSON.stringify(currentIds) === JSON.stringify(newOrderIds)) return;
    
    // Create a document fragment to reorder without multiple reflows
    const fragment = document.createDocumentFragment();
    const itemsMap = {};
    
    // Create a map of id -> element
    Array.from(this.children).forEach(item => {
      itemsMap[item.getAttribute('data-id')] = item;
    });
    
    // Add elements to fragment in new order
    newOrderIds.forEach(id => {
      if (itemsMap[id]) {
        fragment.appendChild(itemsMap[id]);
      }
    });
    
    // Replace all children with the reordered fragment
    this.innerHTML = '';
    this.appendChild(fragment);
  }
}

// Register the custom element
customElements.define('sortable-list', SortableList);
