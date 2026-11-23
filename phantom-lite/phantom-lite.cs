// Phantom Lite - ultra-light activity keeper for Manic Time.
// Sends a harmless Shift keystroke once per second so the machine never looks
// idle, controlled by a single tray on/off toggle. No window, tiny footprint.
using System;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

class PhantomLite : ApplicationContext
{
    [DllImport("user32.dll")]
    static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    static extern bool DestroyIcon(IntPtr hIcon);

    [DllImport("kernel32.dll")]
    static extern IntPtr GetCurrentProcess();

    [DllImport("kernel32.dll")]
    static extern bool SetProcessWorkingSetSize(IntPtr proc, IntPtr min, IntPtr max);

    const byte VK_SHIFT = 0x10;
    const uint KEYEVENTF_KEYUP = 0x0002;

    NotifyIcon tray;
    Timer timer;
    Timer trimTimer;
    ToolStripMenuItem toggleItem;
    Icon iconOn;
    Icon iconOff;
    bool active = true;

    // Remembers the last on/off choice next to the exe, so a restart restores it.
    static readonly string StateFile =
        Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "phantom-lite.state");

    [STAThread]
    static void Main()
    {
        // Single instance: a second launch just exits, never two tickers at once.
        bool isNew;
        using (var mutex = new System.Threading.Mutex(true, "PhantomLiteSingleInstance", out isNew))
        {
            if (!isNew) { return; }
            Application.EnableVisualStyles();
            Application.Run(new PhantomLite());
        }
    }

    PhantomLite()
    {
        iconOn = BuildDot(Color.LimeGreen);
        iconOff = BuildDot(Color.Gray);

        // Restore last state (default: active).
        try { if (File.Exists(StateFile) && File.ReadAllText(StateFile).Trim() == "off") active = false; }
        catch { }

        timer = new Timer();
        timer.Interval = 1000; // once per second
        timer.Tick += OnTick;

        // Keep the physical footprint tiny: return unused pages to Windows every
        // 60s regardless of on/off state, so an idle tray app holds only a few MB.
        trimTimer = new Timer();
        trimTimer.Interval = 60000;
        trimTimer.Tick += (s, e) => Trim();
        trimTimer.Enabled = true;

        toggleItem = new ToolStripMenuItem("Активность включена");
        toggleItem.Click += (s, e) => SetActive(!active);

        var exitItem = new ToolStripMenuItem("Выход");
        exitItem.Click += (s, e) => { tray.Visible = false; Application.Exit(); };

        var menu = new ContextMenuStrip();
        menu.Items.Add(toggleItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(exitItem);

        tray = new NotifyIcon();
        tray.Text = "Phantom Lite";
        tray.ContextMenuStrip = menu;
        tray.Visible = true;
        // Left click on the tray icon also toggles.
        tray.MouseClick += (s, e) => { if (e.Button == MouseButtons.Left) SetActive(!active); };

        Apply(false);
        Trim();
    }

    void Trim()
    {
        try { SetProcessWorkingSetSize(GetCurrentProcess(), (IntPtr)(-1), (IntPtr)(-1)); }
        catch { }
    }

    void OnTick(object sender, EventArgs e)
    {
        // Side-effect-free: a Shift down+up registers as keyboard input for Manic
        // Time but changes nothing the user is typing.
        keybd_event(VK_SHIFT, 0, 0, UIntPtr.Zero);
        keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
    }

    void SetActive(bool value)
    {
        active = value;
        try { File.WriteAllText(StateFile, active ? "on" : "off"); } catch { }
        Apply(true);
    }

    void Apply(bool notify)
    {
        timer.Enabled = active;
        toggleItem.Checked = active;
        tray.Icon = active ? iconOn : iconOff;
        tray.Text = active ? "Phantom Lite: активность ВКЛ" : "Phantom Lite: активность ВЫКЛ";
        if (notify)
        {
            tray.BalloonTipTitle = "Phantom Lite";
            tray.BalloonTipText = active ? "Активность ВКЛЮЧЕНА" : "Активность ВЫКЛЮЧЕНА";
            tray.ShowBalloonTip(800);
        }
    }

    // A small coloured dot icon, generated at runtime so no .ico file is needed.
    static Icon BuildDot(Color color)
    {
        using (var bmp = new Bitmap(16, 16))
        {
            using (var g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);
                using (var b = new SolidBrush(color)) g.FillEllipse(b, 2, 2, 11, 11);
            }
            IntPtr h = bmp.GetHicon();
            Icon ico = (Icon)Icon.FromHandle(h).Clone();
            DestroyIcon(h); // clone keeps its own copy; free the GDI handle
            return ico;
        }
    }
}
