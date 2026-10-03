from pathlib import Path
import sys


def source(text):
    text = text.replace(r"\t", "\t")
    return text.replace(chr(92) * 2 + "\n", chr(92) + "\n")


def replace_once(text, old, new, description):
    if text.count(old) != 1:
        raise SystemExit(f"Unexpected Zotero source while updating {description}")
    return text.replace(old, new, 1)


def replace_section(text, start_marker, end_marker, replacement, required, description):
    start = text.find(start_marker)
    end = text.find(end_marker, start)
    if start < 0 or end < 0:
        raise SystemExit(f"Could not locate Zotero source section for {description}")

    section = text[start:end]
    if any(marker not in section for marker in required):
        raise SystemExit(f"Unexpected Zotero source while updating {description}")
    return text[:start] + replacement + text[end:]


script_path = Path(sys.argv[1])
script = script_path.read_text()

old_actors = source(r"""\t# Remove deleted actors
\tremove_between 'AboutTranslations: \{' '^  },' $file
\tremove_between 'CookieBanner: \{' '^  },' $file
\tremove_between 'PictureInPictureLauncher: \{' '^  },' $file
\tremove_between 'PictureInPictureToggle: \{' '^  },' $file
\tremove_between 'PictureInPicture: \{' '^  },' $file
\tremove_between 'Thumbnails: \{' '^  },' $file
\tremove_between 'Translations: \{' '^  },' $file
\tremove_between 'TranslationsEngine: \{' '^  },' $file
\tremove_between 'AudioPlayback: \{' '^  },' $file
""")
new_actors = source(r"""\t# Remove deleted actors
\t# Entries in the JSWINDOWACTORS/JSPROCESSACTORS literals:
\tremove_between '^  AudioPlayback: \{' '^  },' $file
\tremove_between '^  CookieBanner: \{' '^  },' $file
\tremove_between '^  Thumbnails: \{' '^  },' $file
\tremove_between '^  Translations: \{' '^  },' $file
\tremove_between '^  TranslationsEngine: \{' '^  },' $file
\t# Entries added conditionally after the literals:
\tremove_between '^  JSWINDOWACTORS\.AboutTranslations = \{' '^  \};' $file
\tremove_between '^  JSWINDOWACTORS\.PictureInPictureLauncher = \{' '^  \};' $file
\tremove_between '^  JSWINDOWACTORS\.PictureInPictureToggle = \{' '^  \};' $file
\tremove_between '^  JSWINDOWACTORS\.PictureInPicture = \{' '^  \};' $file
""")
script = replace_once(script, old_actors, new_actors, "Firefox actor cleanup")

old_remote_settings = source(r"""\t# This file loads remote-settings.sys.mjs, but if it's empty Zotero crashes
""")
new_fcntl = source(r"""\t# Cast variadic fcntl flags explicitly for the Unix ABI.
\tif [[ $platform != win* ]]; then
\t\treplace_line 'ctypes\.int \/\* \.\.\. \*\/,' '"...",' modules/subprocess/subprocess_shared_unix.js
\t\treplace_line 'libc\.fcntl\(fds\[0\], LIBC\.F_SETFD, LIBC\.FD_CLOEXEC\);' 'libc.fcntl(fds[0], LIBC.F_SETFD, ctypes.int(LIBC.FD_CLOEXEC));' modules/subprocess/subprocess_unix.worker.js
\t\treplace_line 'libc\.fcntl\(fds\[1\], LIBC\.F_SETFD, LIBC\.FD_CLOEXEC\);' 'libc.fcntl(fds[1], LIBC.F_SETFD, ctypes.int(LIBC.FD_CLOEXEC));' modules/subprocess/subprocess_unix.worker.js
\t\treplace_line 'libc\.fcntl\(fds\[1\], LIBC\.F_SETFL, LIBC\.O_NONBLOCK\);' 'libc.fcntl(fds[1], LIBC.F_SETFL, ctypes.int(LIBC.O_NONBLOCK));' modules/subprocess/subprocess_unix.worker.js
\t\treplace_line 'libc\.fcntl\(fds\[0\], LIBC\.F_SETFL, LIBC\.O_NONBLOCK\);' 'libc.fcntl(fds[0], LIBC.F_SETFL, ctypes.int(LIBC.O_NONBLOCK));' modules/subprocess/subprocess_unix.sys.mjs
\t\treplace_line 'libc\.fcntl\(fds\[0\], LIBC\.F_SETFD, LIBC\.FD_CLOEXEC\);' 'libc.fcntl(fds[0], LIBC.F_SETFD, ctypes.int(LIBC.FD_CLOEXEC));' modules/subprocess/subprocess_unix.sys.mjs
\t\treplace_line 'libc\.fcntl\(fds\[1\], LIBC\.F_SETFD, LIBC\.FD_CLOEXEC\);' 'libc.fcntl(fds[1], LIBC.F_SETFD, ctypes.int(LIBC.FD_CLOEXEC));' modules/subprocess/subprocess_unix.sys.mjs
\tfi
\t
""")
script = replace_once(script, old_remote_settings, new_fcntl + old_remote_settings, "Unix fcntl arguments")

old_css = source(r"""\t# Hide search bar, Themes and Plugins tabs, and sidebar footer
\techo '.main-search, button[name="theme"], button[name="plugin"], sidebar-footer { display: none; }' >> $file
""")
new_css = source(r"""\t# Hide the search bar and the whole sidebar, since we only ever show plugins and the main pane
\t# is already headed "Manage Your Plugins"
\techo '.main-search, #sidebar { display: none; }' >> $file
\t# Center the content in the window now that it isn't offset by the sidebar
\techo '#full { grid-template-columns: 1fr; }' >> $file
\techo '#content { max-width: calc(var(--page-main-content-width) + var(--main-margin-start)); margin-inline: auto; }' >> $file
""")
script = replace_once(script, old_css, new_css, "add-on layout")

new_addons = source(r"""\tfile="chrome/toolkit/content/mozapps/extensions/aboutaddons-utils.mjs"
\t# Hide unsigned-addon warning
\treplace_line 'export function isUnsignedWarningMessageDisabled\(\) \{' \\
\t\t'export function isUnsignedWarningMessageDisabled() {if (true) return true;' $file
\t# Use our own localized string for blocked plugin notification
\treplace_line 'details-notification-hard-blocked-\$\{typeSuffix\}' 'plugins-blocked-plugin' $file
\t# Hide Recommendations tab in sidebar and recommendations in main pane
\treplace_line 'function isDiscoverEnabled\(\) \{' 'function isDiscoverEnabled() {return false;' $file

\tfile="chrome/toolkit/content/mozapps/extensions/components/addon-details.mjs"
\t# Hide Private Browsing setting in addon details
\treplace_line 'pbRow\.' '\/\/pbRow.' $file
\treplace_line 'let isAllowed = await isAllowedInPrivateBrowsing' '\/\/let isAllowed = await isAllowedInPrivateBrowsing' $file
\t# Open plugin links in external browser
\treplace_line 'let homepageURL = homepageRow.querySelector\(\"a\"\);' 'let homepageURL = homepageRow.querySelector\(\"\.text-link\"\);' $file
\treplace_line 'homepageURL.href = addon.homepageURL;' 'homepageURL.setAttribute("href", addon.homepageURL);' $file
\treplace_line '<a target="_blank" dir="ltr"><\/a>' \\
\t\t'<label target="_blank" class="text-link" dir="ltr"><\/label>' $file

\tfile="chrome/toolkit/content/mozapps/extensions/components/addon-card.mjs"
\t# Use our own strings for the removal prompt
\treplace_line 'let \{ BrowserAddonUI \} = windowRoot.window;' '' $file
\treplace_line 'await BrowserAddonUI.promptRemoveExtension' 'promptRemoveExtension' $file

\t# Customize empty-list message
\treplace_line 'createEmptyListMessage\(\) {' 'createEmptyListMessage() {
        var p = document.createElement("p");
        p.id = "empty-list-message";
        return p;' chrome/toolkit/content/mozapps/extensions/components/addon-list.mjs

\t# Add zotero.ftl to the addons page for our own localized strings
\treplace_line 'href="toolkit\/about\/aboutAddons.ftl"' 'href="toolkit\/about\/aboutAddons.ftl" \/>\n    <link rel="localization" href="zotero.ftl"' \\
\t\tchrome/toolkit/content/mozapps/extensions/aboutaddons.html

""")
addons_start = '\tfile="chrome/toolkit/content/mozapps/extensions/aboutaddons.js"\n'
addons_end = '\t# TODO: Use our own strings, but for now fix the bundled English ones\n'
script = replace_section(
    script,
    addons_start,
    addons_end,
    new_addons,
    ("isCorrectlySigned", "windowRoot.ownerGlobal"),
    "add-on source paths",
)

script = replace_once(
    script,
    source(r"""\treplace_line '= Extensions' '= Plugins' localization/en-US/toolkit/about/aboutAddons.ftl
"""),
    "",
    "obsolete add-on localization",
)
script = replace_once(
    script,
    source(r"""\t# Hide Recommendations tab in sidebar and recommendations in main pane
\treplace_line 'function isDiscoverEnabled\(\) \{' 'function isDiscoverEnabled() {return false;' chrome/toolkit/content/mozapps/extensions/aboutaddonsCommon.js
"""),
    "",
    "obsolete add-on recommendation path",
)

old_dialog_loader = source(r"""\t\t\tServices.scriptloader.loadSubScript(\"chrome:\/\/zotero\/content\/include.js\", this);
""")
new_dialog_loader = old_dialog_loader + source(r"""\t\t\tServices.scriptloader.loadSubScript(\"chrome:\/\/zotero\/content\/titlebar.js\", this);
\t\t\tServices.scriptloader.loadSubScript(\"chrome:\/\/zotero\/content\/customElements.js\", this);
""")
script = replace_once(script, old_dialog_loader, new_dialog_loader, "common dialog helpers")

toolbar_path = "chrome/toolkit/content/global/elements/browser-custom-element.mjs\n"
toolbar_adjustments = source(r"""\t# Add the dropmarker for toolbarbuttons with wantdropmarker, which Firefox no longer creates
\treplace_line 'this.appendChild\(this.constructor.fragment.cloneNode\(true\)\);' \\
\t\t'this.appendChild(this.constructor.fragment.cloneNode(true));

        if (this.hasAttribute("wantdropmarker")) {
          let dropmarker = document.createXULElement("dropmarker");
          dropmarker.setAttribute("type", "menu");
          dropmarker.className = "toolbarbutton-menu-dropmarker";
          this.appendChild(dropmarker);
        }' chrome/toolkit/content/global/elements/toolbarbutton.js
\t# Let clicks on the dropmarker pass through to the toolbarbutton, which only opens its menu
\t# when it's the original event target, as xul.css did when Firefox created the dropmarker
\techo '.toolbarbutton-menu-dropmarker { pointer-events: none; }' >> chrome/toolkit/content/global/xul.css
""")
script = replace_once(script, toolbar_path, toolbar_path + toolbar_adjustments, "toolbar dropmarker support")

script = replace_section(
    script,
    "\t# Remove aria-autocomplete unnecessarily added to search-textbox to not confuse screen readers",
    "\t# Remove non-native text input styles",
    "",
    ("search-textbox.js",),
    "removed search-textbox",
)

old_popup = source(r"""\t# By default, an autocomplete popup's width is calculated based on the input that opened it.
\t# Allow an ancestor to designate itself as the width container instead. (For creator inputs.)
\treplace_line 'aElement.getBoundingClientRect\(\).width' \\
\t\t'(aElement.closest(".autocomplete-popup-width-container") || aElement).getBoundingClientRect().width' \\
\t\tchrome/toolkit/content/global/elements/autocomplete-popup.js
""")
new_popup = source(r"""\t# Size an autocomplete popup to the input that opened it, or to an ancestor that designates
\t# itself as the width container. Firefox sizes the popup to its content. (For creator inputs.)
\treplace_line '\/\/ invalidate\(\) depends on the width attribute' \\
\t\t'let widthElement = aElement.closest(".autocomplete-popup-width-container") || aElement;
        this.style.setProperty("--panel-width", Math.max(widthElement.getBoundingClientRect().width, 100) + "px");
        \/\/ invalidate() depends on the width attribute' \\
\t\tchrome/toolkit/content/global/elements/autocomplete-popup.js
""")
script = replace_once(script, old_popup, new_popup, "autocomplete popup sizing")

if "--check" in sys.argv[2:]:
    print("Zotero ESR 153 source adjustments apply cleanly")
elif "--print" in sys.argv[2:]:
    sys.stdout.write(script)
else:
    script_path.write_text(script)