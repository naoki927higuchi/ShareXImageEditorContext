using Microsoft.Win32;
using System.Diagnostics;

if (args.Length == 0) return;

var shareX = FindShareX();
if (shareX is null)
{
    MessageBox("ShareX.exe が見つかりません。ShareX をインストールしてから再実行してください。");
    return;
}

foreach (var image in args.Where(File.Exists).Distinct(StringComparer.OrdinalIgnoreCase))
{
    Process.Start(new ProcessStartInfo
    {
        FileName = shareX,
        Arguments = $"-ImageEditor {Quote(image)}",
        UseShellExecute = false,
        WorkingDirectory = Path.GetDirectoryName(shareX)!
    });
}

static string? FindShareX()
{
    var candidates = new List<string>();
    foreach (var root in new[] { Registry.CurrentUser, Registry.LocalMachine })
    foreach (var view in new[] { RegistryView.Registry64, RegistryView.Registry32 })
    {
        try
        {
            using var hklm = root.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", false);
            if (hklm is not null)
                foreach (var key in hklm.GetSubKeyNames())
                using (var app = hklm.OpenSubKey(key))
                    if (app?.GetValue("DisplayName") is string n && n.Contains("ShareX", StringComparison.OrdinalIgnoreCase) && app.GetValue("InstallLocation") is string p)
                        candidates.Add(Path.Combine(p, "ShareX.exe"));
        } catch { }
    }
    candidates.Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "ShareX", "ShareX.exe"));
    candidates.Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "ShareX", "ShareX.exe"));
    return candidates.FirstOrDefault(File.Exists);
}

static string Quote(string value) => "\"" + value.Replace("\"", "\\\"") + "\"";
static void MessageBox(string text) => System.Windows.Forms.MessageBox.Show(text, "ShareX Image Editor", MessageBoxButtons.OK, MessageBoxIcon.Error);
