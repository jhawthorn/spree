Backend.Shipment = Ember.Object.extend
  manifestItems: (->
    order = this.get('order')
    shipment = this
    $.map this.manifest, (item) ->
      item.original_quantity = item.quantity
      item.line_item = order.lineItemByVariantID(item.variant_id)
      item.variant = item.line_item.variant
      item.shipment = shipment
      Backend.ManifestItem.create(item)
  ).property('manifestItems')

  adjustItems: (variant_id, quantity, original_quantity) ->
    order_id = this.get('order.id')
    id = this.get('id')
    url = "/api/orders/#{order_id}/shipments/#{id}"
    shipment = this
    if original_quantity != quantity
      new_quantity = 0
      if original_quantity < quantity
        url += "/add"
        new_quantity = (quantity - original_quantity)
      else if original_quantity > quantity
        url += "/remove"
        new_quantity = (original_quantity - quantity)
      $.ajax
        url: url
        type: "PUT"
        data:
          variant_id: variant_id
          quantity: new_quantity
      .then (response) ->
        shipment.get('order').advance()