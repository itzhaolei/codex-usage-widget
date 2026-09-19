using QuotaBubble.Services;
using System.ComponentModel;
using System.Globalization;
using System.Windows;
using System.Windows.Media;
using Controls = System.Windows.Controls;

namespace QuotaBubble;

public sealed class UpdateProgressWindow : Window
{
    private readonly Controls.ProgressBar _progressBar;
    private readonly Controls.TextBlock _progressText;
    private bool _allowClose;

    public UpdateProgressWindow(string message)
    {
        Title = "Quota Bubble";
        Width = 360;
        Height = 154;
        ResizeMode = ResizeMode.NoResize;
        WindowStartupLocation = WindowStartupLocation.CenterOwner;
        ShowInTaskbar = false;

        var panel = new Controls.Grid { Margin = new Thickness(24, 20, 24, 20) };
        panel.RowDefinitions.Add(new Controls.RowDefinition { Height = GridLength.Auto });
        panel.RowDefinitions.Add(new Controls.RowDefinition { Height = new GridLength(18) });
        panel.RowDefinitions.Add(new Controls.RowDefinition { Height = new GridLength(22) });

        var label = new Controls.TextBlock
        {
            Text = message,
            FontSize = 14,
            FontWeight = FontWeights.SemiBold,
            Margin = new Thickness(0, 0, 0, 14)
        };
        Controls.Grid.SetRow(label, 0);
        panel.Children.Add(label);

        _progressBar = new Controls.ProgressBar
        {
            Minimum = 0,
            Maximum = 100,
            Height = 14,
            IsIndeterminate = true
        };
        Controls.Grid.SetRow(_progressBar, 1);
        panel.Children.Add(_progressBar);

        _progressText = new Controls.TextBlock
        {
            Text = "0%",
            FontSize = 12,
            Foreground = Brushes.DimGray,
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Bottom
        };
        Controls.Grid.SetRow(_progressText, 2);
        panel.Children.Add(_progressText);
        Content = panel;
        Closing += PreventEarlyClose;
    }

    public void Report(DownloadProgress progress)
    {
        var receivedMb = progress.BytesReceived / 1_048_576d;
        if (progress.Percentage is int percentage && progress.TotalBytes is long totalBytes)
        {
            _progressBar.IsIndeterminate = false;
            _progressBar.Value = percentage;
            _progressText.Text = string.Format(
                CultureInfo.CurrentCulture,
                "{0}% · {1:0.0} / {2:0.0} MB",
                percentage,
                receivedMb,
                totalBytes / 1_048_576d);
        }
        else
        {
            _progressBar.IsIndeterminate = true;
            _progressText.Text = string.Format(CultureInfo.CurrentCulture, "{0:0.0} MB", receivedMb);
        }
    }

    public void CloseAfterDownload()
    {
        _allowClose = true;
        Close();
    }

    private void PreventEarlyClose(object? sender, CancelEventArgs e)
    {
        if (!_allowClose) e.Cancel = true;
    }
}
