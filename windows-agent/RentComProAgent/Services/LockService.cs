using System.Runtime.InteropServices;
using Microsoft.Extensions.Logging;

namespace RentComProAgent.Services
{
    public class LockService
    {
        private readonly ILogger<LockService> _logger;
        private bool _isLocked = false;
        private Form? _lockForm;

        // Windows API imports for blocking input
        [DllImport("user32.dll")]
        private static extern bool BlockInput(bool block);

        public LockService(ILogger<LockService> logger)
        {
            _logger = logger;
        }

        public void LockDevice()
        {
            if (_isLocked)
            {
                _logger.LogInformation("Device already locked");
                return;
            }

            try
            {
                _logger.LogWarning("Locking device...");

                // Block keyboard and mouse
                BlockInput(true);

                // Show fullscreen lock form
                ShowLockScreen();

                _isLocked = true;
                _logger.LogInformation("Device locked successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error locking device");
                BlockInput(false); // Ensure input is unblocked on error
            }
        }

        public void UnlockDevice()
        {
            if (!_isLocked)
            {
                _logger.LogInformation("Device not locked");
                return;
            }

            try
            {
                _logger.LogInformation("Unlocking device...");

                // Unblock keyboard and mouse
                BlockInput(false);

                // Close lock screen
                if (_lockForm != null && !_lockForm.IsDisposed)
                {
                    _lockForm.Invoke(() => _lockForm.Close());
                    _lockForm = null;
                }

                _isLocked = false;
                _logger.LogInformation("Device unlocked successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error unlocking device");
            }
        }

        private void ShowLockScreen()
        {
            // Create lock form on a separate thread
            var thread = new Thread(() =>
            {
                try
                {
                    _lockForm = new Form
                    {
                        Text = "RentComPro - Device Locked",
                        FormBorderStyle = FormBorderStyle.None,
                        WindowState = FormWindowState.Maximized,
                        TopMost = true,
                        BackColor = Color.FromArgb(220, 53, 69), // Red background
                        StartPosition = FormStartPosition.CenterScreen
                    };

                    // Prevent closing with Alt+F4
                    _lockForm.FormClosing += (s, e) =>
                    {
                        if (_isLocked)
                        {
                            e.Cancel = true;
                        }
                    };

                    // Main message label
                    var messageLabel = new Label
                    {
                        Text = "🔒 DEVICE LOCKED",
                        Font = new Font("Segoe UI", 48, FontStyle.Bold),
                        ForeColor = Color.White,
                        AutoSize = false,
                        TextAlign = ContentAlignment.MiddleCenter,
                        Dock = DockStyle.Fill
                    };

                    // Contact info panel
                    var panel = new Panel
                    {
                        Dock = DockStyle.Bottom,
                        Height = 200,
                        BackColor = Color.FromArgb(200, 40, 50)
                    };

                    var contactLabel = new Label
                    {
                        Text = "Payment Overdue\n\nPlease contact:\n\nPhone: +91 9876543210\nEmail: support@rentcompro.com",
                        Font = new Font("Segoe UI", 18, FontStyle.Regular),
                        ForeColor = Color.White,
                        AutoSize = false,
                        TextAlign = ContentAlignment.MiddleCenter,
                        Dock = DockStyle.Fill
                    };

                    panel.Controls.Add(contactLabel);
                    _lockForm.Controls.Add(messageLabel);
                    _lockForm.Controls.Add(panel);

                    // Make form stay on top
                    _lockForm.TopMost = true;
                    _lockForm.ShowInTaskbar = false;

                    Application.Run(_lockForm);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error showing lock screen");
                }
            });

            thread.SetApartmentState(ApartmentState.STA);
            thread.Start();
        }

        public bool IsLocked => _isLocked;
    }
}
