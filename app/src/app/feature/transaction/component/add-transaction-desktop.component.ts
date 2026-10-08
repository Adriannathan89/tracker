import { Component, signal, inject, HostListener } from '@angular/core';
import { Router } from '@angular/router';
import { FormBuilder, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { UserRecordsService } from '../../../core/service/user/user-records.service';
import { AddTransactionAmountHeroComponent } from '../ui/add-transaction/add-transaction-amount-hero.component';
import { AddTransactionDetailsFormComponent } from '../ui/add-transaction/add-transaction-details-form.component';
import { AddTransactionActionsDesktopComponent } from '../ui/add-transaction/add-transaction-actions-desktop.component';
import { LucideUsers } from '@lucide/angular';

const QUICK_AMOUNTS = [
  { label: '10rb',  value: 10_000 },
  { label: '25rb',  value: 25_000 },
  { label: '50rb',  value: 50_000 },
  { label: '100rb', value: 100_000 },
  { label: '250rb', value: 250_000 },
  { label: '500rb', value: 500_000 },
];

@Component({
  selector: 'app-add-transaction-desktop',
  standalone: true,
  imports: [
    AddTransactionAmountHeroComponent,
    AddTransactionDetailsFormComponent,
    AddTransactionActionsDesktopComponent,
    LucideUsers,
  ],
  template: `
    <div class="flex justify-center px-8 py-8">
      <div class="w-full max-w-[720px] flex flex-col gap-4 animate-fade-slide-up">

        <!-- Hutang toggle -->
        <button type="button" (click)="goToFriends()"
          class="flex items-center gap-3 px-4 py-3 rounded-[12px] border transition cursor-pointer"
          [style.background]="'var(--bw-amber-soft)'"
          [style.borderColor]="'var(--bw-amber)'">
          <div class="w-8 h-8 rounded-[8px] flex items-center justify-center shrink-0"
               style="background:var(--bw-amber);color:#fff">
            <svg lucideUsers class="w-4 h-4" style="stroke-width:2.2"></svg>
          </div>
          <div class="text-left">
            <div class="text-[13px] font-bold" style="color:var(--bw-amber-ink)">Catat sebagai hutang/piutang?</div>
            <div class="text-[11px]" style="color:var(--bw-amber-ink);opacity:0.7">Klik di sini → pilih teman dulu</div>
          </div>
        </button>

        <app-add-transaction-amount-hero
          [formattedAmount]="formattedAmount()"
          [rawAmount]="rawAmount()"
          [quickAmounts]="quickAmounts"
          [onQuickSelect]="setRawAmount"
        />

        <app-add-transaction-details-form
          [form]="form"
        />

        <app-add-transaction-actions-desktop
          [saving]="saving()"
          [onSubmitAgain]="submitAndAgain"
          [onSubmit]="submitOnce"
        />

      </div>
    </div>
  `,
})
export class AddTransactionDesktopSubPage {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private recordsService = inject(UserRecordsService);
  private snackBar = inject(MatSnackBar);

  readonly quickAmounts = QUICK_AMOUNTS;

  rawAmount = signal(0);
  saving = signal(false);

  form = this.fb.group({
    title: ['', Validators.required],
    description: [''],
    date: [this.todayISO()],
  });

  formattedAmount(): string {
    const v = this.rawAmount();
    return v === 0 ? '0' : new Intl.NumberFormat('id-ID').format(v);
  }

  @HostListener('window:keydown', ['$event'])
  onGlobalKey(e: KeyboardEvent) {
    const target = e.target as HTMLElement | null;
    const inTextField = target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement;

    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault();
      this.handleSubmit(false);
      return;
    }
    if (e.key === 'Escape') {
      e.preventDefault();
      this.router.navigate(['/transaction']);
      return;
    }
    if (inTextField || e.ctrlKey || e.metaKey || e.altKey) return;
    if (e.key >= '0' && e.key <= '9') {
      this.rawAmount.update(v => Math.min(v * 10 + parseInt(e.key, 10), 999_999_999));
      e.preventDefault();
    } else if (e.key === 'Backspace') {
      this.rawAmount.update(v => Math.floor(v / 10));
      e.preventDefault();
    }
  }

  async handleSubmit(andAgain: boolean) {
    if (this.rawAmount() === 0) {
      this.snackBar.open('Masukkan jumlah terlebih dahulu.', 'Tutup', { duration: 2000 });
      return;
    }
    if (!this.form.controls.title.value?.trim()) {
      this.snackBar.open('Judul tidak boleh kosong.', 'Tutup', { duration: 2000 });
      return;
    }
    this.saving.set(true);
    try {
      await this.recordsService.createRecord(
        this.form.controls.title.value!.trim(),
        this.form.controls.description.value ?? '',
        this.rawAmount(),
        this.form.controls.date.value!,
      );
      this.snackBar.open('Transaksi tersimpan!', 'Tutup', { duration: 2500 });
      if (andAgain) {
        this.form.reset({ title: '', description: '', date: this.todayISO() });
        this.rawAmount.set(0);
      } else {
        this.router.navigate(['/transaction']);
      }
    } catch {
      this.snackBar.open('Gagal menyimpan. Coba lagi.', 'Tutup', { duration: 3000 });
    } finally {
      this.saving.set(false);
    }
  }

  goToFriends = () => this.router.navigate(['/friends']);
  setRawAmount = (value: number) => this.rawAmount.set(value);
  submitAndAgain = () => this.handleSubmit(true);
  submitOnce = () => this.handleSubmit(false);

  private todayISO(): string {
    const d = new Date();
    d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
    return d.toISOString().slice(0, 10);
  }
}
