import { Component, Input } from '@angular/core';
import { LucideDelete, LucideUsers } from '@lucide/angular';

@Component({
  selector: 'app-add-transaction-mobile-phase1',
  standalone: true,
  imports: [LucideDelete, LucideUsers],
  styleUrls: ['./add-transaction.styles.css'],
  template: `
    <div class="flex flex-col gap-4 px-5 pt-3 pb-4 animate-fade-in">

      <div class="text-center py-4">
        <div class="text-[11px] font-semibold uppercase tracking-[0.1em] text-bw-ink-3 mb-2">Jumlah</div>
        <div class="mono leading-none" style="font-size:52px;font-weight:800;letter-spacing:-0.04em;color:var(--bw-ink)">
          <span class="text-bw-ink-3" style="font-size:28px">Rp </span>{{ formattedAmount }}
        </div>
      </div>

      <div class="grid grid-cols-3 gap-2.5 px-2">
        @for (n of numbers; track n) {
          <button type="button" class="numpad-btn" (click)="onPressNum(n.toString())">{{ n }}</button>
        }
        <button type="button" class="numpad-btn" (click)="onPressNum('000')">000</button>
        <button type="button" class="numpad-btn" (click)="onPressNum('0')">0</button>
        <button type="button" class="numpad-btn numpad-del" (click)="onPressNum('del')">
          <svg lucideDelete class="w-5 h-5" style="stroke-width:1.8"></svg>
        </button>
      </div>

      <button type="button" (click)="onNext()"
        class="mx-2 py-4 rounded-[12px] bg-bw-ink text-bw-on-ink text-[15px] font-semibold cursor-pointer hover:opacity-90 transition">
        Lanjutkan →
      </button>

      <button type="button" (click)="onDebt()"
        class="mx-2 flex items-center justify-center gap-2 py-3 rounded-[12px] border cursor-pointer transition"
        style="background:var(--bw-amber-soft);border-color:var(--bw-amber);color:var(--bw-amber-ink)">
        <svg lucideUsers class="w-4 h-4" style="stroke-width:2.2"></svg>
        <span class="text-[13px] font-semibold">Catat sebagai hutang/piutang</span>
      </button>

    </div>
  `,
})
export class AddTransactionMobilePhase1Component {
  @Input() formattedAmount = '0';
  @Input() onPressNum: (key: string) => void = () => {};
  @Input() onNext: () => void = () => {};
  @Input() onDebt: () => void = () => {};

  readonly numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
}
