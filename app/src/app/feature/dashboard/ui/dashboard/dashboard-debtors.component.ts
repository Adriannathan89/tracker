import { Component, EventEmitter, Input, Output } from '@angular/core';
import { Debt } from '../../../../core/model/debt.model';

@Component({
  selector: 'app-dashboard-debtors',
  standalone: true,
  imports: [],
  styleUrls: ['./dashboard-ui.styles.css'],
  template: `
    <div class="bw-card p-5 animate-fade-slide-up" style="animation-delay:130ms">
      <h3 class="text-[15px] font-bold text-bw-ink m-0 mb-3">Yang masih ngutang</h3>

      @if (debts.length === 0) {
        <p class="text-[13px] text-bw-ink-3 py-2">Tidak ada hutang aktif</p>
      } @else {
        @for (d of debts; track d.id; let i = $index) {
          <div class="flex items-center gap-3 py-2.5" [class.friend-debt-row]="i > 0">
            <span class="w-9 h-9 rounded-full bg-bw-sunken text-bw-ink flex items-center justify-center text-[13px] font-bold shrink-0">
              {{ (d.debtor.username || '?').slice(0,1).toUpperCase() }}
            </span>
            <div class="flex-1 min-w-0">
              <div class="text-[14px] font-semibold text-bw-ink truncate">{{ d.debtor.username }}</div>
              <div class="flex items-center gap-1.5 mt-0.5">
                @if (d.category) {
                  <span class="text-[9px] font-semibold px-1.5 py-[2px] rounded-full"
                        [style.background]="catBg(d.category)"
                        [style.color]="catColor(d.category)">
                    {{ d.category }}
                  </span>
                }
                @if (d.description) {
                  <span class="text-[12px] text-bw-ink-3 truncate">{{ d.description }}</span>
                }
              </div>
            </div>
            <div class="text-right shrink-0">
              <div class="mono text-[13px] font-bold text-bw-ink">Rp {{ formatRupiah(d.amount) }}</div>
              <button
                class="text-[11px] font-semibold mt-1 px-2 py-0.5 rounded-[6px] cursor-pointer"
                style="background:var(--bw-lime);color:var(--bw-ink)"
                (click)="pay.emit(d.id)">
                Lunas
              </button>
            </div>
          </div>
        }
      }
    </div>
  `,
})
export class DashboardDebtorsComponent {
  @Input({ required: true }) debts: Debt[] = [];
  @Input({ required: true }) formatRupiah!: (n: number) => string;
  @Output() pay = new EventEmitter<string>();

  private readonly _cat: { [k: string]: [string, string] } = {
    makanan:   ['var(--bw-amber-soft)',   'var(--bw-amber)'],
    minuman:   ['var(--bw-emerald-soft)', 'var(--bw-emerald)'],
    transport: ['rgba(132,204,22,0.12)',  'var(--bw-lime)'],
    belanja:   ['var(--bw-red-soft)',     'var(--bw-red)'],
    hiburan:   ['rgba(168,85,247,0.12)',  '#a855f7'],
    tagihan:   ['var(--bw-sunken)',       'var(--bw-ink-3)'],
    kesehatan: ['var(--bw-green-soft)',   'var(--bw-green)'],
  };

  catBg    = (c: string) => (this._cat[c] ?? ['var(--bw-sunken)', 'var(--bw-ink-3)'])[0];
  catColor = (c: string) => (this._cat[c] ?? ['var(--bw-sunken)', 'var(--bw-ink-3)'])[1];
}
