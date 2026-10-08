import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideWallet, LucideArrowDown, LucideArrowUp } from '@lucide/angular';
import { UserRecord } from '../../../../core/model/record.model';

@Component({
  selector: 'app-dashboard-stat-row-desktop',
  standalone: true,
  imports: [CommonModule, LucideWallet, LucideArrowDown, LucideArrowUp],
  styleUrls: ['./dashboard-ui.styles.css'],
  template: `
    <div class="grid gap-3" style="grid-template-columns: repeat(3,1fr)">
      <div class="stat-card animate-fade-slide-up" style="animation-delay:50ms">
        <div class="flex justify-between items-start mb-2">
          <div class="text-[12px] font-semibold tracking-[0.08em] uppercase text-bw-ink-3">Tunai</div>
          <span class="icon-box" style="background:var(--bw-green-soft)">
            <svg lucideWallet class="w-[15px] h-[15px]" style="color:var(--bw-green);stroke-width:2"></svg>
          </span>
        </div>
        <div class="mono text-[24px] font-bold text-bw-ink">{{ formatRupiah(records?.cash ?? 0) }}</div>
        <div class="text-[11px] text-bw-ink-3 mt-1">dari {{ totalIncomeCount }} pemasukan</div>
      </div>

      <div class="stat-card animate-fade-slide-up" style="animation-delay:100ms">
        <div class="flex justify-between items-start mb-2">
          <div class="text-[12px] font-semibold tracking-[0.08em] uppercase text-bw-ink-3">Piutang</div>
          <span class="icon-box" style="background:var(--bw-lime-soft)">
            <svg lucideArrowDown class="w-[15px] h-[15px]" style="color:var(--bw-lime-ink);stroke-width:2"></svg>
          </span>
        </div>
        <div class="mono text-[24px] font-bold text-bw-ink">{{ formatRupiah(records?.receivable ?? 0) }}</div>
        <div class="text-[11px] text-bw-ink-3 mt-1">dari teman-teman</div>
      </div>

      <div class="stat-card animate-fade-slide-up" style="animation-delay:150ms">
        <div class="flex justify-between items-start mb-2">
          <div class="text-[12px] font-semibold tracking-[0.08em] uppercase text-bw-ink-3">Hutang</div>
          <span class="icon-box" style="background:var(--bw-amber-soft)">
            <svg lucideArrowUp class="w-[15px] h-[15px]" style="color:var(--bw-amber);stroke-width:2"></svg>
          </span>
        </div>
        <div class="mono text-[24px] font-bold text-bw-ink">{{ formatRupiah(records?.debt ?? 0) }}</div>
        <div class="text-[11px] text-bw-ink-3 mt-1">perlu dilunasi</div>
      </div>
    </div>
  `,
})
export class DashboardStatRowDesktopComponent {
  @Input({ required: true }) records: UserRecord | null = null;
  @Input({ required: true }) totalIncomeCount = 0;
  @Input({ required: true }) formatRupiah!: (n: number) => string;
}
