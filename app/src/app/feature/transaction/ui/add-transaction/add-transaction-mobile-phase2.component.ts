import { Component, Input } from '@angular/core';
import { ReactiveFormsModule, FormControl, FormGroup } from '@angular/forms';
import { LucideCheck } from '@lucide/angular';

@Component({
  selector: 'app-add-transaction-mobile-phase2',
  standalone: true,
  imports: [ReactiveFormsModule, LucideCheck],
  styleUrls: ['./add-transaction.styles.css'],
  template: `
    <div class="flex flex-col gap-4 px-5 pt-3 pb-6 animate-fade-slide-up">

      <div class="flex items-center justify-between py-3 px-4 rounded-[12px]"
           style="background:var(--bw-elevated)">
        <div>
          <div class="text-[11px] font-semibold uppercase tracking-wider text-bw-ink-3">Jumlah</div>
          <div class="mono text-[22px] font-bold text-bw-ink leading-tight">
            Rp {{ formattedAmount }}
          </div>
        </div>
        <button type="button" (click)="onEditAmount()"
          class="text-[13px] font-semibold text-bw-ink-3 hover:text-bw-ink cursor-pointer px-3 py-1.5 rounded-[8px] hover:bg-bw-sunken transition">
          ← Ubah
        </button>
      </div>

      <div>
        <label class="bw-label">Judul</label>
         <input class="bw-input-mobile" placeholder="Contoh: Makan siang"
           [formControl]="control('title')" />
      </div>

      <div>
        <label class="bw-label">Tanggal</label>
        <input class="bw-input-mobile" type="date" [formControl]="control('date')" />
      </div>

      <div>
        <label class="bw-label">Catatan <span class="text-bw-ink-3 font-normal">(opsional)</span></label>
         <input class="bw-input-mobile" placeholder="Tambahkan catatan…"
           [formControl]="control('description')" />
      </div>

      <button type="button" (click)="onSubmit()" [disabled]="saving"
        class="flex items-center justify-center gap-2 py-4 rounded-[12px] bg-bw-ink text-bw-on-ink text-[15px] font-semibold cursor-pointer hover:opacity-90 transition disabled:opacity-50 mt-2">
        <svg lucideCheck class="w-5 h-5 shrink-0"></svg>
        {{ saving ? 'Menyimpan…' : 'Simpan Transaksi' }}
      </button>
      <button type="button" (click)="onCancel()"
        class="py-3 rounded-[12px] border border-bw-border text-bw-ink-2 text-[14px] font-semibold cursor-pointer hover:bg-bw-sunken transition">
        Batal
      </button>

    </div>
  `,
})
export class AddTransactionMobilePhase2Component {
  @Input() formattedAmount = '0';
  @Input() form!: FormGroup;
  @Input() saving = false;
  @Input() onEditAmount: () => void = () => {};
  @Input() onSubmit: () => void = () => {};
  @Input() onCancel: () => void = () => {};

  control(name: 'title' | 'date' | 'description'): FormControl {
    return this.form.get(name) as FormControl;
  }
}
