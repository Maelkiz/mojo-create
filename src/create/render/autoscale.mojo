struct AutoScale:
    """How the program's design resolution maps onto the window."""

    comptime OFF    = 0  # canvas is the window; resizing changes ctx.width/height
    comptime FIT    = 1  # uniform scale to fit, centred, bars on the short axis
    comptime EXTEND = 2  # same scale as FIT, no bars — leftover becomes extra world
