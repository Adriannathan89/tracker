import { Component, Input } from '@angular/core';
import { UserRecord } from '../../../../core/model/record.model';

@Component({
  selector: 'app-dashboard-stat-strip-mobile',
  standalone: true,
  imports: [],
  styleUrls: ['./dashboard-ui.styles.css'],
  template: `
    <div class="grid grid-cols-3 gap-2">
      <div class="stat-card">
        <div class="text-[11px] font-semibold tracking-wider uppercase text-bw-ink-3 mb-1">Tunai</div>
        <div class="mono text-[13px] font-bold text-bw-ink leading-tight">Rp {{ formatRupiah(records?.cash ?? 0) }}</div>
      </div>
      <div class="stat-card">
        <div class="text-[11px] font-semibold tracking-wider uppercase text-bw-ink-3 mb-1">Piutang</div>
        <div class="mono text-[13px] font-bold text-bw-ink leading-tight">Rp {{ formatRupiah(records?.receivable ?? 0) }}</div>
      </div>
      <div class="stat-card">
        <div class="text-[11px] font-semibold tracking-wider uppercase text-bw-ink-3 mb-1">Hutang</div>
        <div class="mono text-[13px] font-bold text-bw-ink leading-tight">Rp {{ formatRupiah(records?.debt ?? 0) }}</div>
      </div>
    </div>
  `,
})
export class DashboardStatStripMobileComponent {
  @Input({ required: true }) records: UserRecord | null = null;
  @Input({ required: true }) formatRupiah!: (n: number) => string;
}
