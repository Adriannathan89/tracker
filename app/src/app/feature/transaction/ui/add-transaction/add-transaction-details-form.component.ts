import { Component, Input } from '@angular/core';
import { ReactiveFormsModule, FormControl, FormGroup } from '@angular/forms';

@Component({
  selector: 'app-add-transaction-details-form',
  standalone: true,
  imports: [ReactiveFormsModule],
  styleUrls: ['./add-transaction.styles.css'],
  template: `
    <div class="bw-card" style="padding:24px">
      <div class="grid gap-4" style="grid-template-columns:1fr 1fr">

        <div style="grid-column:1/-1">
          <label class="bw-label">Judul</label>
          <input class="bw-input-desktop" placeholder="Contoh: Makan di restoran"
            [formControl]="control('title')" />
        </div>

        <div>
          <label class="bw-label">Tanggal</label>
          <input class="bw-input-desktop" type="date" [formControl]="control('date')" />
        </div>

        <div>
          <label class="bw-label">Catatan <span class="text-bw-ink-3 font-normal">(opsional)</span></label>
          <input class="bw-input-desktop" placeholder="Misal: bayar patungan…"
            [formControl]="control('description')" />
        </div>

      </div>
    </div>
  `,
})
export class AddTransactionDetailsFormComponent {
  @Input() form!: FormGroup;

  control(name: 'title' | 'date' | 'description'): FormControl {
    return this.form.get(name) as FormControl;
  }
}
