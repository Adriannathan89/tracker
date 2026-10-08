import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideArrowUp, LucideChevronDown } from '@lucide/angular';
import { SparkLineComponent } from '../../../../shared/ui/spark-line.component';
import { UserRecord } from '../../../../core/model/record.model';

@Component({
  selector: 'app-dashboard-hero-desktop',
  standalone: true,
  imports: [CommonModule, SparkLineComponent, LucideArrowUp, LucideChevronDown],
  styleUrls: ['./dashboard-ui.styles.css'],
  template: `
    <div class="hero-card animate-fade-slide-up">
      <div class="flex justify-between items-start">
        <div>
          <div class="text-[12px] font-semibold tracking-[0.1em] uppercase" style="color:var(--hero-dim)">Saldo Bersih</div>
          <div class="mono animate-count" style="font-size:clamp(40px,5vw,64px); font-weight:700; line-height:1.05; margin-top:8px; letter-spacing:-0.04em;">
            Rp <span style="color:var(--bw-lime)">{{ formatRupiah(records?.balance ?? 0) }}</span>
          </div>
          <div class="flex gap-2 mt-3 flex-wrap">
            <span class="chip chip-lime-dark">
              <svg lucideArrowUp class="w-3 h-3"></svg>
              {{ monthlyTrendLabel }}
            </span>
            <span class="chip chip-ghost-dark">
              Tunai Rp {{ formatRupiah(records?.cash ?? 0) }}
            </span>
          </div>
        </div>
        <button class="flex items-center gap-1 text-[13px] font-medium px-3 py-2 rounded-[10px] cursor-pointer"
                style="background:var(--hero-ghost);color:var(--hero-fg)">
          {{ currentMonth }} <svg lucideChevronDown class="w-3.5 h-3.5"></svg>
        </button>
      </div>
      <div style="margin: 20px -12px -28px;">
        <app-spark-line [data]="sparkData" [height]="90" [width]="760"></app-spark-line>
      </div>
    </div>
  `,
})
export class DashboardHeroDesktopComponent {
  @Input({ required: true }) records: UserRecord | null = null;
  @Input({ required: true }) currentMonth!: string;
  @Input({ required: true }) sparkData: number[] = [];
  @Input({ required: true }) monthlyTrendLabel = '';
  @Input({ required: true }) formatRupiah!: (n: number) => string;
}
