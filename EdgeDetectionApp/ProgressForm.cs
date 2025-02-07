using System;
using System.Windows.Forms;

namespace EdgeDetectionApp
{
    public class ProgressForm : Form
    {
        private ProgressBar progressBar;

        public ProgressForm()
        {
            this.Text = "Przetwarzanie obrazu";
            this.Size = new System.Drawing.Size(400, 150);
            this.StartPosition = FormStartPosition.CenterScreen;

            InitializeComponents();
        }

        private void InitializeComponents()
        {
            // Pasek postępu
            progressBar = new ProgressBar();
            progressBar.Location = new System.Drawing.Point(50, 50);
            progressBar.Size = new System.Drawing.Size(300, 25);
            progressBar.Style = ProgressBarStyle.Marquee; // Pasek w stylu ciągłego ruchu
            progressBar.MarqueeAnimationSpeed = 30; // Szybkość animacji

            // Dodanie kontrolki do formularza
            this.Controls.Add(progressBar);
        }
    }
}
