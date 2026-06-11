const text = `[
{
    "locked": false,
    "mouse": false,
    "release": true,
    "repeat": false,
    "longPress": false,
    "non_consuming": false,
    "auto_consuming": false,
    "has_description": false,
    "modmask": 64,
    "submap": "",
    "submap_universal": "false",
    "key": "SUPER_L",
    "keycode": 0,
    "catch_all": false,
    "description": "",
    "dispatcher": "__lua",
    "arg": "11"
},
{
    "locked": false,
    "mouse": false,
    "release": false,
    "repeat": false,
    "longPress": false,
    "non_consuming": false,
    "auto_consuming": false,
    "has_description": false,
    "modmask": 64,
    "submap": "",
    "submap_universal": "false",
    "key": "ESCAPE",
    "keycode": 0,
    "catch_all": false,
    "description": "",
    "dispatcher": "__lua",
    "arg": "13"
},
{
    "locked": false,
    "mouse": false,
    "release": false,
    "repeat": false,
    "longPress": false,
    "non_consuming": false,
    "auto_consuming": false,
    "has_description": false,
    "modmask": 64,
    "submap": "",
    "submap_universal": "false",
    "key": "N",
    "keycode": 0,
    "catch_all": false,
    "description": "",
    "dispatcher": "__lua",
    "arg": "15"
},
{
    "locked": true,
    "mouse": false,
    "release": false,
    "repeat": false,
    "longPress": false,
    "non_consuming": false,
    "auto_consuming": false,
    "has_description": false,
    "modmask": 12,
    "submap": "",
    "submap_universal": "false",
    "key": "C",
    "keycode": 0,
    "catch_all": false,
    "description": "",
    "dispatcher": "__lua",
    "arg": "17"
},
{
    "locked": false,
    "mouse": false,
    "release": false,
    "repeat": false,
    "longPress": false,
    "non_consuming": false,
    "auto_consuming": false,
    "has_description": false,
    "modmask": 64,
    "submap": "",
    "submap_universal": "false",
    "key": "K",
    "keycode": 0,
    "catch_all": false,
    "description": "",
    "dispatcher": "__lua",
    "arg": "19"
}
]`;

try {
    const binds = JSON.parse(text);
    const formattedBinds = [];

    for (const b of binds) {
        const action = b.dispatcher + (b.arg ? " " + b.arg : "");
        
        let mods = [];
        const m = b.modmask;
        if (m & 64) mods.push("Super");
        if (m & 8) mods.push("Alt");
        if (m & 4) mods.push("Ctrl");
        if (m & 1) mods.push("Shift");
        
        let keyText = b.key;
        if (keyText === "") {
            if (b.catch_all) {
                keyText = "Catchall";
            } else {
                continue;
            }
        }

        let bindText = mods.join(" + ");
        if (bindText !== "") bindText += " + ";
        bindText += keyText;

        formattedBinds.push({
            bind: bindText,
            action: action
        });
    }
    console.log(formattedBinds);
} catch(e) {
    console.error(e);
}
