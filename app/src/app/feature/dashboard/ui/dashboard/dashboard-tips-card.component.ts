import { Component } from '@angular/core';
import { LucideZap } from '@lucide/angular';

@Component({
  selector: 'app-dashboard-tips-card',
  standalone: true,
  imports: [LucideZap],
  styleUrls: ['./dashboard-ui.styles.css'],
  template: `
    <div class="bw-card p-4 animate-fade-slide-up" style="animation-delay:180ms; background:var(--bw-lime-soft); border-color:transparent">
      <div class="flex gap-3">
        <div class="w-8 h-8 rounded-[8px] flex items-center justify-center shrink-0"
             style="background:var(--bw-ink)">
          <svg lucideZap class="w-4 h-4" style="color:var(--bw-lime);stroke-width:2.2"></svg>
        </div>
        <div>
          <div class="text-[13px] font-bold" style="color:var(--bw-lime-ink)">Tips dari tracker</div>
          <div class="text-[12px] mt-1 leading-relaxed" style="color:var(--bw-lime-ink)">
            Coba rutin catat setiap hari biar kamu tau kemana perginya duit kamu tiap bulan.
          </div>
        </div>
      </div>
    </div>
  `,
})
export class DashboardTipsCardComponent {}
