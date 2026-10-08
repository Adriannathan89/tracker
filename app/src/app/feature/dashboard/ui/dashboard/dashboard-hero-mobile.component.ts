import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideArrowUp } from '@lucide/angular';
import { SparkLineComponent } from '../../../../shared/ui/spark-line.component';
import { UserRecord } from '../../../../core/model/record.model';

@Component({
  selector: 'app-dashboard-hero-mobile',
  standalone: true,
  imports: [CommonModule, SparkLineComponent, LucideArrowUp],
  styleUrls: ['./dashboard-ui.styles.css'],
  template: `
    <div class="hero-card animate-fade-slide-up">
      <div class="flex justify-between items-start">
        <div>
          <div class="text-[12px] font-semibold tracking-[0.1em] uppercase" style="color:var(--hero-dim)">Saldo Bersih</div>
          <div class="mono animate-count" style="font-size:42px;font-weight:700;line-height:1.05;margin-top:6px;letter-spacing:-0.04em">
            Rp <span style="color:var(--bw-lime)">{{ formatRupiah(records?.balance ?? 0) }}</span>
          </div>
          <div class="flex gap-2 mt-2">
            <span class="chip chip-lime-dark">
              <svg lucideArrowUp class="w-3 h-3"></svg>
              {{ monthlyTrendLabel }}
            </span>
          </div>
        </div>
      </div>
      <div style="margin:16px -12px -28px">
        <app-spark-line [data]="sparkData" [height]="60" [width]="360"></app-spark-line>
      </div>
    </div>
  `,
})
export class DashboardHeroMobileComponent {
  @Input({ required: true }) records: UserRecord | null = null;
  @Input({ required: true }) sparkData: number[] = [];
  @Input({ required: true }) monthlyTrendLabel = '';
  @Input({ required: true }) formatRupiah!: (n: number) => string;
}
