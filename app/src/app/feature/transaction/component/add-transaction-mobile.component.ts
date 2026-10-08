import { Component, signal, inject } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { UserRecordsService } from '../../../core/service/user/user-records.service';
import { AddTransactionMobilePhase1Component } from '../ui/add-transaction/add-transaction-mobile-phase1.component';
import { AddTransactionMobilePhase2Component } from '../ui/add-transaction/add-transaction-mobile-phase2.component';

@Component({
  selector: 'app-add-transaction-mobile',
  standalone: true,
  imports: [
    AddTransactionMobilePhase1Component,
    AddTransactionMobilePhase2Component,
  ],
  template: `
    <div class="flex flex-col h-full">

      <!-- ─ Phase 1: Amount + Numpad ─ -->
      @if (phase === 1) {
        <app-add-transaction-mobile-phase1
          [formattedAmount]="formattedAmount()"
          [onPressNum]="pressNum"
          [onNext]="goToPhase2"
          [onDebt]="goToFriends"
        />
      }

      <!-- ─ Phase 2: Details ─ -->
      @if (phase === 2) {
        <app-add-transaction-mobile-phase2
          [formattedAmount]="formattedAmount()"
          [form]="form"
          [saving]="saving()"
          [onEditAmount]="backToPhase1"
          [onSubmit]="submit"
          [onCancel]="goBack"
        />
      }
    </div>
  `,
})
export class AddTransactionMobileSubPage {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private recordsService = inject(UserRecordsService);
  private snackBar = inject(MatSnackBar);

  phase = 1;
  rawAmount = signal(0);
  saving = signal(false);

  form = this.fb.group({
    title: ['', Validators.required],
    description: [''],
    date: [this.todayDate()],
  });

  formattedAmount(): string {
    const v = this.rawAmount();
    return v === 0 ? '0' : new Intl.NumberFormat('id-ID').format(v);
  }

  pressNum = (key: string) => {
    if (key === 'del') {
      const s = String(this.rawAmount()).slice(0, -1);
      this.rawAmount.set(s ? Number(s) : 0);
      return;
    }
    const current = this.rawAmount() === 0 ? '' : String(this.rawAmount());
    const next = Number(current + key);
    if (next > 999_999_999) return;
    this.rawAmount.set(next);
  };

  goToPhase2 = () => {
    if (this.rawAmount() === 0) {
      this.snackBar.open('Masukkan jumlah terlebih dahulu.', 'Tutup', { duration: 2000 });
      return;
    }
    this.phase = 2;
  };

  submit = async () => {
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
      this.router.navigate(['/transaction']);
    } catch {
      this.snackBar.open('Gagal menyimpan. Coba lagi.', 'Tutup', { duration: 3000 });
    } finally {
      this.saving.set(false);
    }
  };

  goBack = () => this.router.navigate(['/transaction']);
  goToFriends = () => this.router.navigate(['/friends']);
  backToPhase1 = () => { this.phase = 1; };

  private todayDate(): string {
    const d = new Date();
    d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
    return d.toISOString().slice(0, 10);
  }
}
