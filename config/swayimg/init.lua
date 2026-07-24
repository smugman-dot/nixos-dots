-- ~/.config/swayimg/init.lua
-- Fully keyboard-driven swayimg configuration
-- Wipes swayimg's built-in key/mouse bindings and replaces them with a
-- vim-flavored scheme that covers viewer, gallery, and slideshow modes.

-- ============================================================================
-- General
-- ============================================================================

swayimg.enable_antialiasing(true)
swayimg.enable_exif_orientation(true)

-- ============================================================================
-- Image list
-- ============================================================================

swayimg.imagelist.set_order("alpha")
swayimg.imagelist.enable_recursive(true)
swayimg.imagelist.enable_adjacent(true)
swayimg.imagelist.enable_fsmon(true)

-- ============================================================================
-- Viewer defaults
-- ============================================================================

swayimg.viewer.set_default_scale("fill")
swayimg.viewer.set_default_position("center")
swayimg.viewer.enable_centering(true)
swayimg.viewer.enable_loop(true)
swayimg.viewer.limit_preload(3)
swayimg.viewer.limit_history(10)
swayimg.viewer.set_window_background(0xff101010)
swayimg.viewer.set_mark_color(0xffe0a030)

-- ============================================================================
-- Gallery defaults
-- ============================================================================

swayimg.gallery.set_aspect("fill")
swayimg.gallery.set_thumb_size(180)
swayimg.gallery.set_padding_size(6)
swayimg.gallery.set_border_size(2)
swayimg.gallery.set_border_color(0xffe0a030)
swayimg.gallery.set_selected_color(0xff303030)
swayimg.gallery.set_unselected_color(0xff181818)
swayimg.gallery.set_window_color(0xff101010)
swayimg.gallery.set_mark_color(0xffe0a030)
swayimg.gallery.enable_hover(false) -- pure keyboard selection, no mouse hover
swayimg.gallery.enable_preload(true)
swayimg.gallery.enable_pstore(true)

-- ============================================================================
-- Text overlay
-- ============================================================================

swayimg.text.set_size(15)
swayimg.text.set_padding(10)
swayimg.text.set_foreground(0xffe0e0e0)
swayimg.text.set_background(0x80000000)
swayimg.text.set_shadow(0x00000000)
swayimg.text.set_timeout(0) -- always visible while toggled on
swayimg.text.set_status_timeout(3)

swayimg.viewer.set_text("bottomleft", {
	"{name}",
	"{list.index}/{list.total}\t{scale}",
})
swayimg.gallery.set_text("bottomleft", {
	"{name}",
	"{list.index}/{list.total}",
})

-- Text layer starts hidden; toggle with "t"
swayimg.text.hide()

-- ============================================================================
-- Helpers
-- ============================================================================

local function shell_escape(s)
	return "'" .. s:gsub("'", [['\'']]) .. "'"
end

local function current_entry()
	local mode = swayimg.get_mode()
	if mode == "gallery" then
		return swayimg.gallery.get_image()
	else
		return swayimg.viewer.get_image()
	end
end

-- Move the current/selected image to the trash via `gio trash`, then drop
-- it from the in-memory list so it disappears immediately.
local function trash_current()
	local entry = current_entry()
	if not entry then
		return
	end
	local path = entry.path
	local ok = os.execute("gio trash " .. shell_escape(path))
	if ok then
		swayimg.imagelist.remove(path)
		swayimg.text.set_status("Trashed: " .. path)
	else
		swayimg.text.set_status("Trash failed (is gio installed?): " .. path)
	end
end

-- Copy the current image's file path to the clipboard (wl-clipboard).
local function copy_path()
	local entry = current_entry()
	if not entry then
		return
	end
	os.execute("printf '%s' " .. shell_escape(entry.path) .. " | wl-copy")
	swayimg.text.set_status("Copied path")
end

-- Copy the actual image data to the clipboard (wl-clipboard).
local function copy_image()
	local entry = current_entry()
	if not entry then
		return
	end
	os.execute("wl-copy < " .. shell_escape(entry.path))
	swayimg.text.set_status("Copied image")
end

-- Relative zoom, since the API only exposes absolute/fixed scale.
local function zoom(factor)
	local scale = swayimg.viewer.get_scale()
	swayimg.viewer.set_abs_scale(scale * factor)
end

local function toggle_text()
	if swayimg.text.visible() then
		swayimg.text.hide()
	else
		swayimg.text.show()
	end
end

local function export_current()
	local entry = current_entry()
	if not entry then
		return
	end
	local dir = os.getenv("HOME") .. "/Pictures"
	local out = dir .. "/swayimg-export-" .. os.date("%Y%m%d-%H%M%S") .. ".png"
	swayimg.viewer.export(out)
	swayimg.text.set_status("Exported: " .. out)
end

-- ============================================================================
-- Viewer mode keybindings
-- ============================================================================

swayimg.viewer.bind_reset()

-- Navigation
swayimg.viewer.on_key("l", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("Right", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("space", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("h", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("Left", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("BackSpace", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("g", function() swayimg.viewer.switch_image("first") end)
swayimg.viewer.on_key("Home", function() swayimg.viewer.switch_image("first") end)
swayimg.viewer.on_key("G", function() swayimg.viewer.switch_image("last") end)
swayimg.viewer.on_key("End", function() swayimg.viewer.switch_image("last") end)
swayimg.viewer.on_key("Ctrl-l", function() swayimg.viewer.switch_image("next_dir") end)
swayimg.viewer.on_key("Ctrl-h", function() swayimg.viewer.switch_image("prev_dir") end)
swayimg.viewer.on_key("r", function() swayimg.viewer.switch_image("random") end)
swayimg.viewer.on_key("F5", function() swayimg.viewer.reload() end)

-- Zoom / pan reset
swayimg.viewer.on_key("plus", function() zoom(1.1) end)
swayimg.viewer.on_key("equal", function() zoom(1.1) end)
swayimg.viewer.on_key("minus", function() zoom(0.9) end)
swayimg.viewer.on_key("0", function() swayimg.viewer.reset() end)
swayimg.viewer.on_key("1", function() swayimg.viewer.set_fix_scale("real") end)
swayimg.viewer.on_key("2", function() swayimg.viewer.set_fix_scale("fit") end)
swayimg.viewer.on_key("3", function() swayimg.viewer.set_fix_scale("fill") end)
swayimg.viewer.on_key("4", function() swayimg.viewer.set_fix_scale("width") end)
swayimg.viewer.on_key("5", function() swayimg.viewer.set_fix_scale("height") end)

-- Rotate / flip
swayimg.viewer.on_key("comma", function() swayimg.viewer.rotate(270) end)
swayimg.viewer.on_key("period", function() swayimg.viewer.rotate(90) end)
swayimg.viewer.on_key("z", function() swayimg.viewer.flip_horizontal() end)
swayimg.viewer.on_key("Z", function() swayimg.viewer.flip_vertical() end)

-- Animation
swayimg.viewer.on_key("a", function() swayimg.viewer.set_animation() end)
swayimg.viewer.on_key("bracketright", function() swayimg.viewer.next_frame() end)
swayimg.viewer.on_key("bracketleft", function() swayimg.viewer.prev_frame() end)

-- Mode / window
swayimg.viewer.on_key("Tab", function() swayimg.set_mode("gallery") end)
swayimg.viewer.on_key("s", function() swayimg.set_mode("slideshow") end)
swayimg.viewer.on_key("f", function() swayimg.set_fullscreen() end)
swayimg.viewer.on_key("F11", function() swayimg.set_fullscreen() end)
swayimg.viewer.on_key("t", toggle_text)

-- File actions
swayimg.viewer.on_key("m", function() swayimg.viewer.mark_image() end)
swayimg.viewer.on_key("d", trash_current)
swayimg.viewer.on_key("Delete", trash_current)
swayimg.viewer.on_key("y", copy_path)
swayimg.viewer.on_key("Y", copy_image)
swayimg.viewer.on_key("e", export_current)

-- Quit
swayimg.viewer.on_key("q", function() swayimg.exit() end)
swayimg.viewer.on_key("Escape", function() swayimg.exit() end)

-- ============================================================================
-- Gallery mode keybindings
-- ============================================================================

swayimg.gallery.bind_reset()

-- Navigation
swayimg.gallery.on_key("h", function() swayimg.gallery.switch_image("left") end)
swayimg.gallery.on_key("Left", function() swayimg.gallery.switch_image("left") end)
swayimg.gallery.on_key("l", function() swayimg.gallery.switch_image("right") end)
swayimg.gallery.on_key("Right", function() swayimg.gallery.switch_image("right") end)
swayimg.gallery.on_key("k", function() swayimg.gallery.switch_image("up") end)
swayimg.gallery.on_key("Up", function() swayimg.gallery.switch_image("up") end)
swayimg.gallery.on_key("j", function() swayimg.gallery.switch_image("down") end)
swayimg.gallery.on_key("Down", function() swayimg.gallery.switch_image("down") end)
swayimg.gallery.on_key("g", function() swayimg.gallery.switch_image("first") end)
swayimg.gallery.on_key("Home", function() swayimg.gallery.switch_image("first") end)
swayimg.gallery.on_key("G", function() swayimg.gallery.switch_image("last") end)
swayimg.gallery.on_key("End", function() swayimg.gallery.switch_image("last") end)
swayimg.gallery.on_key("Ctrl-u", function() swayimg.gallery.switch_image("pgup") end)
swayimg.gallery.on_key("Page_Up", function() swayimg.gallery.switch_image("pgup") end)
swayimg.gallery.on_key("Ctrl-d", function() swayimg.gallery.switch_image("pgdown") end)
swayimg.gallery.on_key("Page_Down", function() swayimg.gallery.switch_image("pgdown") end)

-- Thumbnail size
swayimg.gallery.on_key("plus", function()
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() + 20)
end)
swayimg.gallery.on_key("minus", function()
	swayimg.gallery.set_thumb_size(math.max(40, swayimg.gallery.get_thumb_size() - 20))
end)

-- Open / mode switch
swayimg.gallery.on_key("Return", function() swayimg.set_mode("viewer") end)
swayimg.gallery.on_key("space", function() swayimg.set_mode("viewer") end)
swayimg.gallery.on_key("Tab", function() swayimg.set_mode("viewer") end)
swayimg.gallery.on_key("s", function() swayimg.set_mode("slideshow") end)
swayimg.gallery.on_key("f", function() swayimg.set_fullscreen() end)
swayimg.gallery.on_key("F5", function() swayimg.gallery.reload() end)
swayimg.gallery.on_key("t", toggle_text)

-- File actions
swayimg.gallery.on_key("m", function() swayimg.gallery.mark_image() end)
swayimg.gallery.on_key("d", trash_current)
swayimg.gallery.on_key("Delete", trash_current)
swayimg.gallery.on_key("y", copy_path)
swayimg.gallery.on_key("Y", copy_image)

-- Quit
swayimg.gallery.on_key("q", function() swayimg.exit() end)
swayimg.gallery.on_key("Escape", function() swayimg.exit() end)

-- ============================================================================
-- Slideshow mode keybindings
-- ============================================================================
-- Slideshow shares the same function surface as viewer, so give it the
-- essentials: pause/quit/mode-switch. Add more from the viewer section
-- above (swap swayimg.viewer.* for swayimg.slideshow.*) if needed.

swayimg.slideshow.set_timeout(5)
swayimg.slideshow.bind_reset()
swayimg.slideshow.on_key("space", function() swayimg.set_mode("viewer") end)
swayimg.slideshow.on_key("Escape", function() swayimg.set_mode("viewer") end)
swayimg.slideshow.on_key("q", function() swayimg.exit() end)
swayimg.slideshow.on_key("l", function() swayimg.slideshow.switch_image("next") end)
swayimg.slideshow.on_key("h", function() swayimg.slideshow.switch_image("prev") end)
