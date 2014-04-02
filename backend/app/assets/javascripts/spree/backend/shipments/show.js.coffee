
Spree.Shipment = Backbone.Model.extend
  idAttribute: 'number'
  isReady: ->
    this.get('state') == 'ready'
  url: ->
    "/api/orders/#{this.order().id}/shipments/#{this.id}"

  order: ->
    this.get('order')

  advanceOrder: ->
    this.order().advance()

  findVariant: (id) ->
    variant = _.find this.order().variants(), (v) ->
      v.id == id
  imageForVariant: (id) ->
    this.findVariant(id).images[0].mini_url

  findLineItem: (variant_id) ->
    line_item = _.find this.order().get('line_items'), (li) ->
      li.variant_id == variant_id

  manifestItem: (variant_id) ->
    manifest_item = _.find this.get('manifest'), (item) ->
      item.variant_id == variant_id

  willAdjustItem: (variant_id, quantity) ->
    this.manifestItem(variant_id).quantity != quantity

  adjustItems: (variant_id, quantity) ->
    item = this.manifestItem(variant_id)
    new_url = ""
    new_quantity = 0
    if item.quantity < quantity
      new_url = this.url() + "/add"
      new_quantity = (quantity - item.quantity)
    else if item.quantity > quantity
      new_url = this.url() + "/remove"
      new_quantity = (item.quantity - quantity)
    new_url += '.json'

    if new_quantity != 0
      shipment = this
      $.ajax
        type: "PUT",
        url: Spree.url(new_url),
        data: { variant_id: variant_id, quantity: new_quantity }
      .done -> 
        shipment.advanceOrder()


Spree.Admin.ShipmentShow = Backbone.View.extend
  className: "shipment"
  tagName: "div"
  render: ->
    template = _.template($("#shipment_template").html(), { shipment: this.model })
    this.$el.html(template)
    this.$el.find('.select2').select2()

  events:
    "click a.edit-item"      : "toggleItemEdit"
    "click a.cancel-item"    : "toggleItemEdit"
    "click a.save-item"      : "saveItem"
    "click a.delete-item"    : "deleteItem"
    "click a.split-item"     : "startItemSplit"
    "click a.cancel-split"   : "cancelItemSplit"
    "click a.save-split"     : "completeItemSplit"
    "click a.edit-method"    : "toggleMethodEdit"
    "click a.cancel-method"  : "toggleMethodEdit"
    "click a.save-method"    : "saveMethod"
    "click a.edit-tracking"  : "toggleTrackingEdit"
    "click a.cancel-tracking": "toggleTrackingEdit"
    "click a.save-tracking"  : "saveTracking"
    "click a.ship"           : "shipIt"

  toggleItemEdit: (e) ->
    e.preventDefault()
    link = $(e.target)
    link_parent = link.parent()
    link_row = link.parents('tr')

    link_parent.find('a.edit-item').toggle()
    link_parent.find('a.cancel-item').toggle()
    link_parent.find('a.split-item').toggle()
    link_parent.find('a.save-item').toggle()
    link_parent.find('a.delete-item').toggle()

    link_row.find('td.item-qty-show').toggle()
    link_row.find('td.item-qty-edit').toggle()

  saveItem: (e) ->
    e.preventDefault()
    link = $(e.target)
    variant_id = link.data('variant-id')
    quantity_field = link.parents('tr').find('input.line_item_quantity')
    quantity = parseInt(quantity_field.val())

    this.toggleItemEdit(e)
    if this.model.willAdjustItem(variant_id, quantity)
      quantity_field.parents("tr").find("td.item-qty-show, td.item-total").html("<div align='center'><img src='/assets/spinner.gif'></div>")
      this.model.adjustItems(variant_id, quantity)


  deleteItem: (e) ->
    e.preventDefault()
    if confirm(Spree.translations.are_you_sure_delete)
      link = $(e.target)
      variant_id = link.data('variant-id')

      this.model.adjustItems(variant_id, 0)

  startItemSplit: (e) ->
    e.preventDefault()
    link = $(e.target)
    link.parent().find('a.edit-item').toggle()
    link.parent().find('a.split-item').toggle()
    link.parent().find('a.delete-item').toggle()
    variant_id = link.data('variant-id')

    variant = {}
    $.ajax
      type: "GET",
      async: false,
      url: Spree.url(Spree.routes.variants_api + "/#{variant_id}"),
    .success (v) ->
      variant = v
    .error (msg) ->
      console.error(msg);

    max_quantity = link.data('quantity')
    template = Handlebars.compile($('#variant_split_template').text())
    split_item = template
      variant: variant, 
      shipments: this.model.order().get('shipments'),
      max_quantity: max_quantity
    link.closest('tr').after(split_item)
    Spree.Admin.tipMe()

    $('#item_stock_location').select2
      width: 'resolve'
      placeholder: Spree.translations.item_stock_placeholder 

  cancelItemSplit: (e) ->
    e.preventDefault()
    link = $(e.target)
    prev_row = link.closest('tr').prev()
    link.closest('tr').remove()
    prev_row.find('a.edit-item').toggle()
    prev_row.find('a.split-item').toggle()
    prev_row.find('a.delete-item').toggle()


  completeItemSplit: (e) ->
    e.preventDefault();
    link = $(e.target);
    order_number = link.closest('tbody').data('order-number')
    stock_item_row = link.closest('tr')
    variant_id = stock_item_row.data('variant-id')
    quantity = stock_item_row.find('#item_quantity').val()

    stock_location_id = stock_item_row.find('#item_stock_location').val();
    original_shipment = this.model

    selected_shipment = stock_item_row.find($('#item_stock_location').select2('data').element)
    target_shipment_number = selected_shipment.data('shipment-number')
    new_shipment = selected_shipment.data('new-shipment');

    if stock_location_id != 'new_shipment'
      $.ajax
        type: "PUT"
        # TODO: Figure out a better way to get to the collection's URL
        # That'd probably start with actually defining a collection.
        url: Spree.url(original_shipment.order().url() + "/shipments/transfer.json"),
        data:
          source_id: original_shipment.id
          variant_id: variant_id,
          quantity: quantity
          target_id: target_shipment_number if !new_shipment
          stock_location_id: stock_location_id if new_shipment
      .done (order) ->
        original_shipment.order().set(order)
      .error (msg) ->
        console.error(msg)

  toggleMethodEdit: (e) -> 
    e.preventDefault()
    link = $(e.target)
    link.parents('tbody').find('tr.edit-method').toggle()
    link.parents('tbody').find('tr.show-method').toggle()

  saveMethod: (e) ->
    e.preventDefault()
    link = $(e.target)
    shipment = this.model
    selected_shipping_rate_id = link.parents('tbody').find("#selected_shipping_rate_id").val()
    if shipment.get('selected_shipping_rate').id != parseInt(selected_shipping_rate_id)
      $.ajax
        type: 'PUT'
        url: shipment.url()
        data:
          shipment:
            selected_shipping_rate_id: selected_shipping_rate_id
      .done ->
        shipment.advanceOrder()
      .error (msg) ->
        console.error(msg)
    else
      this.toggleMethodEdit(e)

  shipIt: (e) ->
    e.preventDefault()
    shipment = this.model
    $.ajax
      type: 'PUT',
      url: shipment.url() + "/ship.json"
    .done ->
      shipment.advanceOrder()
    .error (msg) ->
      console.error(msg)

  toggleTrackingEdit: (e) ->
    e.preventDefault()
    link = $(e.target)
    tbody = link.parents('tbody')
    tbody.find('tr.edit-tracking').toggle()
    tbody.find('tr.show-tracking').toggle()

  saveTracking: (e) ->
    e.preventDefault()
    tbody = $(e.target).parents('tbody')
    tracking = tbody.find('input#tracking').val()
    this.toggleTrackingEdit(e)
    tbody.find('tr.show-tracking .tracking-value').html(tracking)

    if this.model.get('tracking') != tracking
      $.ajax
        type: 'PUT'
        url: this.model.url()
        data:
          shipment:
            tracking: tracking