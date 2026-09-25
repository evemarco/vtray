// Internal headless tests — no tray is initialised here, so they run in CI
// without a display or a StatusNotifierItem watcher.
module vtray

fn test_tray_creation_and_c_fields() {
	mut t := new()
	t.set_icon('icon.ico')
	t.set_tooltip('tooltip text')
	unsafe {
		assert !isnil(t.ctray.icon)
		assert !isnil(t.ctray.tooltip)
	}
}

fn test_menu_item_defaults() {
	mi := new_menu_item(text: 'action')
	assert mi.text == 'action'
	assert mi.checked == 0
	assert mi.disabled == 0
	assert mi.cb == unsafe { nil }
}

fn test_set_menu_stores_items() {
	mut t := new()
	t.set_menu([
		new_menu_item(text: 'first', checked: 1),
		new_menu_item(text: 'second'),
	])
	assert t.mitems.len == 2
	assert t.mitems[0].checked == 1
	assert t.mitems[1].text == 'second'
	assert t.ctray.menu != unsafe { nil }
}

fn test_separator_and_disabled_flags() {
	mut t := new()
	t.set_menu([new_menu_item(text: '-', disabled: 1)])
	assert t.mitems[0].text == '-'
	assert t.mitems[0].disabled == 1
}
