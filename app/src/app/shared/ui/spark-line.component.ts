import { Component, Input, OnChanges } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-spark-line',
  standalone: true,
  imports: [CommonModule],
  template: `
    <svg
      [attr.viewBox]="'0 0 ' + width + ' ' + height"
      [attr.width]="'100%'"
      [attr.height]="height"
      preserveAspectRatio="none"
      style="display:block;overflow:visible"
    >
      <defs>
        <linearGradient [id]="gradId" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" [attr.stop-color]="color" stop-opacity="0.35" />
          <stop offset="1" [attr.stop-color]="color" stop-opacity="0" />
        </linearGradient>
      </defs>
      <path [attr.d]="areaPath" [attr.fill]="'url(#' + gradId + ')'" />
      <path [attr.d]="linePath" [attr.stroke]="color"
            stroke-width="2.5" fill="none"
            stroke-linejoin="round" stroke-linecap="round" />
    </svg>
  `,
})
export class SparkLineComponent implements OnChanges {
  @Input() data: number[] = [];
  @Input() color = 'currentColor';
  @Input() height = 80;
  @Input() width = 320;

  gradId = 'bwSpark_' + Math.random().toString(36).slice(2, 7);
  linePath = '';
  areaPath = '';

  ngOnChanges() {
    if (!this.data.length) return;
    const max = Math.max(...this.data);
    const min = Math.min(...this.data);
    const range = max - min || 1;
    const points = this.data.map((v, i) => {
      const x = (i / (this.data.length - 1)) * this.width;
      const y = this.height - ((v - min) / range) * (this.height - 12) - 6;
      return { x, y };
    });
    this.linePath = 'M' + points.map(p => `${p.x},${p.y}`).join(' L');
    this.areaPath = `M0,${this.height} L${points.map(p => `${p.x},${p.y}`).join(' L')} L${this.width},${this.height} Z`;
  }
}
