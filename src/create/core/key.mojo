struct Key:
    # Modifier keys
    comptime LEFT_CTRL   = 1073742048
    comptime RIGHT_CTRL  = 1073742052
    comptime LEFT_SHIFT  = 1073742049
    comptime RIGHT_SHIFT = 1073742053
    comptime LEFT_ALT    = 1073742050
    comptime RIGHT_ALT   = 1073742054
    comptime LEFT_SUPER  = 1073742051
    comptime RIGHT_SUPER = 1073742055

    # Arrow keys
    comptime UP    = 1073741906
    comptime DOWN  = 1073741905
    comptime LEFT  = 1073741904
    comptime RIGHT = 1073741903

    # Navigation
    comptime INSERT    = 1073741897
    comptime HOME      = 1073741898
    comptime PAGE_UP   = 1073741899
    comptime PAGE_DOWN = 1073741902
    comptime END       = 1073741901

    # Common keys
    comptime ENTER     = 13
    comptime ESCAPE    = 27
    comptime BACKSPACE = 8
    comptime TAB       = 9
    comptime SPACE     = 32
    comptime DELETE    = 127
    comptime CAPS_LOCK = 1073741881

    # Function keys
    comptime F1  = 1073741882
    comptime F2  = 1073741883
    comptime F3  = 1073741884
    comptime F4  = 1073741885
    comptime F5  = 1073741886
    comptime F6  = 1073741887
    comptime F7  = 1073741888
    comptime F8  = 1073741889
    comptime F9  = 1073741890
    comptime F10 = 1073741891
    comptime F11 = 1073741892
    comptime F12 = 1073741893

    # Letter keys (SDL keycodes match lowercase ASCII)
    comptime A = 97;  comptime B = 98;  comptime C = 99;  comptime D = 100
    comptime E = 101; comptime F = 102; comptime G = 103; comptime H = 104
    comptime I = 105; comptime J = 106; comptime K = 107; comptime L = 108
    comptime M = 109; comptime N = 110; comptime O = 111; comptime P = 112
    comptime Q = 113; comptime R = 114; comptime S = 115; comptime T = 116
    comptime U = 117; comptime V = 118; comptime W = 119; comptime X = 120
    comptime Y = 121; comptime Z = 122

    # Number keys
    comptime NUM_0 = 48; comptime NUM_1 = 49; comptime NUM_2 = 50; comptime NUM_3 = 51
    comptime NUM_4 = 52; comptime NUM_5 = 53; comptime NUM_6 = 54; comptime NUM_7 = 55
    comptime NUM_8 = 56; comptime NUM_9 = 57
