# Disable KWin and use i3gaps as WM
export KDEWM=/usr/bin/i3

# Compositor (Animations, Shadows, Transparency)
# xcompmgr -C
compton -b --backend glx --vsync opengl-swc
