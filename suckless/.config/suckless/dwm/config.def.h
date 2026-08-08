/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int gappx     = 10;        /* gaps between windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayonleft = 0;    /* 0: systray in the right corner, >0: systray on left of status text */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray        = 1;        /* 0 means no systray */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const Bool viewontag         = True;     /* Switch view on tag switch */
static const char *fonts[]          = { "JetBrainsMono Nerd Font:size=11" };
static const char dmenufont[]       = "JetBrainsMono Nerd Font:size=11";
static const char col_gray1[]       = "#1e1e2e";
/*static const char col_gray2[]       = "#45475a";*/
static const char col_gray2[]       = "#313244";
static const char col_gray3[]       = "#cdd6f4";
static const char col_gray4[]       = "#dfdfdf";
static const char col_blue[]        = "#89b4fa";
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray1 },
	[SchemeSel]  = { col_gray3, col_gray2, col_blue },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class 							instance    title       tags mask     isfloating   monitor    float x,y,w,h         floatborderpx*/
	{ "Blueman-manager",  NULL,       NULL,       0,            1,           -1, 				485,190,950,700,  		-1 },
	{ "Galculator", 			NULL,       NULL,       0,            1,           -1,        1550,730,10, 10,      -1 },
	{ "pavucontrol",      NULL,       NULL,       0,            1,           -1, 				485,190,950,700, 		  -1 },
	{ "Thunar", 				  NULL,       NULL,       0,            1,           -1, 				375,135,1170,820, 	  -1 },
	{ "St", 						  NULL,       NULL,       0,            1,           -1, 				485,190,950,700,  	  -1 },
	{ "kitty", 					  NULL,       NULL,       0,            1,           -1, 				410,151,1100,778, 	  -1 },
	{ "gnome-calculator", NULL,       NULL,       0,            1,           -1, 				485,190,385,616, 		  -1 },
};

/* layout(s) */
static const float mfact     = 0.50; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */
static const int refreshrate    = 120; /* refresh rate (per second) for client move/resize */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ NULL,       NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define ALTKEY Mod1Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2]          = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[]    = { "dmenu_run", "-p", ">>> ", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_gray2, "-sf", col_gray3, NULL };
static const char *rofidrun[]    = { "rofi","-show","drun", NULL };
static const char *terminalcmd[] = { "ghostty", NULL };
static const char *yazi[]        = { "ghostty","-e","yazi", NULL };
static const char *term2cmd[]    = { "kitty", NULL };
/*static const char *term2cmd[]    = { "st", "-e", "/usr/bin/fish", NULL };*/
static const char *filecmd[]     = { "thunar", NULL };
/*static const char *webbrowser[]  = { "chromium-browser", NULL };*/
static const char *webbrowser[]  = { "google-chrome-stable", NULL };
static const char *email[]       = { "thunderbird", NULL };
static const char *notatka[]     = { "st","-e","nowa-notatka.sh", NULL };
static const char *newnot[]      = { "st","-e","fzf-nn.sh", NULL };
static const char *notes[]       = { "st","-e","fzf-notes.sh", NULL };
static const char *wallpaper[]   = { "st","-e","yazi","~/Pictures/Wallpaper", NULL };
static const char *btop[]        = { "st","-e","btop", NULL };
static const char *pavucontrol[] = { "pavucontrol", NULL };
static const char *vbreset[]     = { "reset_vol_bri.sh", NULL };
static const char *monsys[]      = { "sensors_monitor_ws.sh","n", NULL };
static const char *printall[]    = { "screenshot-save-inbox.sh", NULL };
static const char *printsel[]    = { "screenshot-save-inbox.sh","-s", NULL };
static const char *wlctl[]       = { "st","-e","/home/hubert/.cargo/bin/wlctl", NULL };
static const char *bluetui[]     = { "st","-e","/home/hubert/.cargo/bin/bluetui", NULL };
static const char *rpower[]      = { "rofi-power-menu.sh", NULL };
static const char *rscr[]        = { "rofi-scripts-menu.sh", NULL };
static const char *rclip[]       = { "rofi-clipboard-menu.sh", NULL };
static const char *rwin[]        = { "rofi-window-switcher.sh", NULL };
static const char *rweb[]        = { "rofi-web-search.sh", NULL };
static const char *rperfm[]      = { "rofi-performance-profile.sh", NULL };
static const char *rwall[]       = { "rofi-wallpaper-switcher.sh", NULL };
static const char *remoji[]      = { "rofi-emoji-selector.sh", NULL };
static const char *xkey[]        = { "rofi-dwm-keys.sh", NULL };
static const char *xpower[]      = { "dmenu-powermenu.sh", NULL };
static const char *rtunedcmd[]   = { "sudo", "systemctl", "restart", "tuned", NULL };
static const char *resdunst[]    = { "restart-dunst.sh", NULL };
static const char *gdriveonoff[] = { "gdrive-on-off.sh", NULL };

/* Multimedia commands */
static const char *upvol[]       = { "/home/hubert/.config/suckless/scripts/volume", "--inc", NULL };
static const char *downvol[]     = { "/home/hubert/.config/suckless/scripts/volume", "--dec", NULL };
static const char *mutevol[]     = { "/home/hubert/.config/suckless/scripts/volume", "--toggle", NULL };

static const char *playpause[]   = { "playerctl", "play-pause", NULL };
static const char *nexttrack[]   = { "playerctl", "next", NULL };
static const char *prevtrack[]   = { "playerctl", "previous", NULL };
static const char *stoptrack[]   = { "playerctl", "stop", NULL };

static const char *brightup[]   = { "brightnessctl", "s", "10%+", NULL };
static const char *brightdown[] = { "brightnessctl", "s", "10%-", NULL };

#include "selfrestart.c"
#include "shiftview.c"
#include <X11/XF86keysym.h>

#include "movestack.c"
static const Key keys[] = {
	/* modifier                     key          function        argument */
	{ MODKEY,                       XK_Return,   spawn,          {.v = terminalcmd } },        /*ghostty*/ 
	{ MODKEY,                       XK_x,        spawn,          {.v = term2cmd } },           /*st*/ 
	{ MODKEY|ShiftMask,             XK_y,        spawn,          {.v = yazi } },               /*ghostty run yazi*/ 
	{ MODKEY,                       XK_space,    spawn,          {.v = rofidrun } },           /*rofi*/
	{ MODKEY,                       XK_Tab,      spawn,          {.v = rwin } },               /*rofi window*/ 
	{ ALTKEY,                       XK_space,    spawn,          {.v = dmenucmd } },           /*dmenu*/
	{ MODKEY|ShiftMask,             XK_space,    spawn,          {.v = rweb } },               /*rofi wyszukaj w google*/ 
	{ MODKEY|ShiftMask,             XK_e,        spawn,          {.v = filecmd } },            /*thunar*/ 
	{ ALTKEY|ShiftMask,             XK_w,        spawn,          {.v = wallpaper } },          /*yazi wybierz tapetę*/ 
	{ MODKEY|ShiftMask,             XK_t,        spawn,          {.v = btop } },               /*btop*/ 
	{ MODKEY|ShiftMask,             XK_p,        spawn,          {.v = email } },              /*thunderbird*/ 
	{ MODKEY,                       XK_n,        spawn,          {.v = notatka } },            /*nowa notatka szablon*/ 
	{ MODKEY,                       XK_i,        spawn,          {.v = newnot } },             /*nowa notatka !0 Inbox | fzf*/ 
	{ MODKEY|ShiftMask,             XK_n,        spawn,          {.v = notes } },              /*Documents Notes | fzf*/ 
	{ MODKEY|ShiftMask,             XK_Return,   spawn,          {.v = webbrowser } },         /*chromium-browser*/ 
	{ MODKEY|ControlMask,           XK_w,        spawn,          {.v = wlctl } },              /*wifi*/ 
	{ MODKEY|ControlMask,           XK_b,        spawn,          {.v = bluetui } },            /*bluetooth*/ 
	{ MODKEY|ControlMask,           XK_p,        spawn,          {.v = pavucontrol } },        /*dźwięk*/ 
	{ MODKEY|ControlMask,           XK_m,        spawn,          {.v = vbreset } },            /*reset głośności/jasności*/ 
  { MODKEY|ControlMask,           XK_f,        spawn,          {.v = rtunedcmd } },          /*fan restart*/     
  { MODKEY|ControlMask,           XK_d,        spawn,          {.v = resdunst } },           /*dunst restart*/     
  { MODKEY|ControlMask,           XK_g,        spawn,          {.v = gdriveonoff } },        /*gdrive on off*/     
	{ MODKEY,                       XK_Print,    spawn,          {.v = printall } },           /*zrzut ekranu*/ 
	{ MODKEY|ShiftMask,             XK_Print,    spawn,          {.v = printsel } },           /*zrzut ekranu z zaznaczenia*/ 
	{ MODKEY|ShiftMask,             XK_c,        spawn,          {.v = rclip } },              /*rofi schowek*/ 
	{ MODKEY|ShiftMask,             XK_m,        spawn,          {.v = remoji } },             /*rofi emoji*/ 
	{ MODKEY|ShiftMask,             XK_r,        spawn,          {.v = rscr } },               /*rofi uruchom skrypt*/ 
	{ MODKEY|ShiftMask,             XK_s,        spawn,          {.v = rperfm } },             /*rofi performance*/ 
	{ MODKEY,                       XK_Escape,   spawn,          {.v = rpower } },             /*rofi menu zasilania*/ 
	{ MODKEY|ShiftMask,             XK_w,        spawn,          {.v = rwall } },              /*rofi wallpaper switcher*/ 
	{ ALTKEY,                       XK_Escape,   spawn,          {.v = xpower } },             /*dmenu menu zasilania*/ 
	{ MODKEY|ShiftMask,             XK_x,        spawn,          {.v = monsys } },             /*monitor sytemu*/ 
  { MODKEY|ShiftMask,             XK_slash,    spawn,          {.v = xkey } },               /*pomoc: skróty*/ 
	{ MODKEY,                       XK_b,        togglebar,      {0} },                        /*pokaż/ukryj dwm bar*/ 
	{ MODKEY,                       XK_j,        focusstack,     {.i = +1 } },                 /*fokus w dół*/ 
	{ MODKEY,                       XK_k,        focusstack,     {.i = -1 } },                 /*fokus w górę*/ 
	{ MODKEY|ShiftMask,             XK_i,        incnmaster,     {.i = +1 } },                 /*okna poziomo*/ 
	{ MODKEY|ShiftMask,             XK_d,        incnmaster,     {.i = -1 } },                 /*okna pionowo*/ 
	{ MODKEY,                       XK_Up,       focusstack,     {.i = -1 } },                 /*fokus w górę*/ 
	{ MODKEY,                       XK_Down,     focusstack,     {.i = +1 } },                 /*fokus w dół*/ 
	{ MODKEY,                       XK_Right,    focusstack,     {.i = +1 } },                 /*fokus w prawo*/ 
	{ MODKEY,                       XK_Left,     focusstack,     {.i = -1 } },                 /*fokus w lewo*/ 
	{ MODKEY,                       XK_h,        setmfact,       {.f = -0.05} },               /*zmniejsz obszar główny*/ 
	{ MODKEY,                       XK_l,        setmfact,       {.f = +0.05} },               /*powiększ obszar główny*/ 
	{ MODKEY|ControlMask,           XK_Left,     setmfact,       {.f = -0.05} },               /*zmniejsz obszar główny*/ 
	{ MODKEY|ControlMask,           XK_Right,    setmfact,       {.f = +0.05} },               /*powiększ obszar główny*/ 
	{ MODKEY|ControlMask,           XK_equal,    resetmfact,     {0} },                        /*resetuj szerokość okien 50/50*/
	{ MODKEY|ShiftMask,             XK_Left,     movestack,      {.i = +1 } },                 /*przesuń okno w lewo*/ 
	{ MODKEY|ShiftMask,             XK_Right,    movestack,      {.i = -1 } },                 /*przesuń okno w prawo*/ 
	{ MODKEY|ShiftMask,             XK_j,        movestack,      {.i = +1 } },                 /*przesuń okno w dół*/ 
	{ MODKEY|ShiftMask,             XK_k,        movestack,      {.i = -1 } },                 /*przesuń okno w górę*/ 
	{ MODKEY,                       XK_q,        killclient,     {0} },                        /*zamknij okno*/ 
	{ MODKEY,                       XK_t,        setlayout,      {.v = &layouts[0]} },         /*układ kafelkowy*/ 
	{ MODKEY,                       XK_f,        setlayout,      {.v = &layouts[1]} },         /*układ pływający*/ 
	{ MODKEY,                       XK_m,        setlayout,      {.v = &layouts[2]} },         /*układ monokl*/ 
	{ MODKEY|ShiftMask,             XK_f,        fullscreen,     {0} },                        /*pełny ekran*/ 
  { MODKEY,                       XK_v,        setlayout,      {0} },                        /*poprzedni układ*/ 
	{ MODKEY|ShiftMask,             XK_v,        togglefloating, {0} },                        /*pływające okno*/ 
	{ MODKEY,                       XK_0,        view,           {.ui = ~0 } },                /*wszystkie tagi*/ 
	{ MODKEY|ShiftMask,             XK_0,        tag,            {.ui = ~0 } },                /*przypisz do wszystkich tagów*/ 
	{ MODKEY,                       XK_comma,    focusmon,       {.i = -1 } },                 /*lewy monitor*/ 
	{ MODKEY,                       XK_period,   focusmon,       {.i = +1 } },                 /*prawy monitor*/ 
	{ MODKEY|ShiftMask,             XK_comma,    tagmon,         {.i = -1 } },                 /*przenieś na lewy monitor*/ 
	{ MODKEY|ShiftMask,             XK_period,   tagmon,         {.i = +1 } },                 /*przenieś na prawy monitor*/ 
	{ MODKEY,                       XK_minus,    setgaps,        {.i = -1 } },                 /*zmniejsz odstępy*/ 
	{ MODKEY,                       XK_equal,    setgaps,        {.i = +1 } },                 /*zwiększ odstępy*/ 
	{ MODKEY|ShiftMask,             XK_equal,    setgaps,        {.i = 0  } },                 /*zeruj odstępy*/ 
	{ MODKEY,                       XK_g,        togglesmartmode,{0} },                        /*tryb smart: bez przerw/ramek*/ 
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
  { MODKEY|ShiftMask,             XK_q,      self_restart,   {0} },                        /* restart dwm*/ 
	{ MODKEY|ControlMask|ShiftMask, XK_q,      quit,           {0} },                        /* wyjście z dwm*/ 
  /* Keybindings for multimedia keys */
	{ 0, XF86XK_AudioRaiseVolume,  spawn, {.v = upvol } },                                   /* głośność +*/ 
	{ 0, XF86XK_AudioLowerVolume,  spawn, {.v = downvol } },                                 /* głośność -*/ 
	{ 0, XF86XK_AudioMute,         spawn, {.v = mutevol } },                                 /* wycisz*/ 
	{ 0, XF86XK_AudioPlay,         spawn, {.v = playpause } },                               /* odtwórz/pauza*/ 
	{ 0, XF86XK_AudioNext,         spawn, {.v = nexttrack } },                               /* następny utwór*/ 
	{ 0, XF86XK_AudioPrev,         spawn, {.v = prevtrack } },                               /* poprzedni utwór*/ 
	{ 0, XF86XK_AudioStop,         spawn, {.v = stoptrack } },                               /* zatrzymaj*/ 
	{ 0, XF86XK_MonBrightnessUp,   spawn, {.v = brightup } },                                /* jasność +*/ 
	{ 0, XF86XK_MonBrightnessDown, spawn, {.v = brightdown } },                              /* jasność -*/ 
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = terminalcmd } },
	/* placemouse options, choose which feels more natural:
	 *    0 - tiled position is relative to mouse cursor
	 *    1 - tiled postiion is relative to window center
	 *    2 - mouse pointer warps to window center
	 *
	 * The moveorplace uses movemouse or placemouse depending on the floating state
	 * of the selected client. Set up individual keybindings for the two if you want
	 * to control these separately (i.e. to retain the feature to move a tiled window
	 * into a floating position).
	 */
	{ ClkClientWin,         MODKEY,         Button1,        moveorplace,    {.i = 1} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemfact,    {0} },
	{ ClkClientWin,         MODKEY|ControlMask, Button3,      resetmfact,     {0} },         /*resetuj szerokość okien 50/50*/
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
