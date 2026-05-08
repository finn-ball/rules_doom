"""Providers shared by rules_doom internals."""

DoomEngineInfo = provider(
    doc = "Describes engine launch metadata used by doom_launch.",
    fields = {
        "runner": "Executable target used to launch the engine.",
        "start_map_style": "How the engine accepts a logical start map, such as 'warp' or 'map'.",
    },
)

DoomWadInfo = provider(
    doc = "Describes a Doom WAD file and launch-time map naming metadata.",
    fields = {
        "wad": "The WAD file.",
        "map_namespace_style": "Map naming style used by launcher semantics, such as 'episode', 'mapxx', or 'unknown'.",
    },
)

DoomTextmapInfo = provider(
    doc = "Describes a generated UDMF TEXTMAP file and its logical map name.",
    fields = {
        "textmap": "Primary TEXTMAP file.",
        "map_name": "Logical map marker name such as MAP01.",
    },
)
