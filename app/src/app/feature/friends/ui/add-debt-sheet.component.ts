import { Component, Inject, signal, inject, ViewChild, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MAT_BOTTOM_SHEET_DATA, MatBottomSheetRef, MatBottomSheetModule } from '@angular/material/bottom-sheet';
import { MatSnackBar } from '@angular/material/snack-bar';
import { LucideX, LucideCheck } from '@lucide/angular';
import { AddDebtFormComponent } from './add-debt-form.component';
import { DebtService } from '../../../core/service/debt/debt.service';

export type AddDebtSheetData = {
  friendId: string;
  friendName: string;
  friendInitial: string;
};

@Component({
  selector: 'app-add-debt-sheet',
  standalone: true,
  imports: [
    CommonModule,
    MatBottomSheetModule,
    LucideX,
    LucideCheck,
    AddDebtFormComponent,
  ],
  styles: [`
    :host {
      display: block;
      width: 100%;
    }

    .sheet-container {
      padding: 12px 16px 24px;
      display: flex;
      flex-direction: column;
      width: 100%;
      box-sizing: border-box;
    }

    .drag-handle {
      width: 36px;
      height: 4px;
      background: var(--bw-border-strong);
      border-radius: 2px;
      margin: 0 auto 14px;
    }

    .sheet-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 16px;
      gap: 8px;
    }

    .header-text {
      flex: 1;
    }

    .header-eyebrow {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      color: var(--bw-ink-3);
      margin-bottom: 4px;
    }

    .header-title {
      font-size: 20px;
      font-weight: 800;
      letter-spacing: -0.03em;
      margin: 0;
    }

    .header-title .friend-name {
      color: var(--bw-ink-2);
    }

    .close-btn {
      all: unset;
      cursor: pointer;
      width: 32px;
      height: 32px;
      border-radius: 10px;
      background: var(--bw-elevated);
      color: var(--bw-ink);
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      flex-shrink: 0;
    }

    .close-btn:hover {
      background: var(--bw-sunken);
    }

    .sheet-body {
      flex: 1;
    }

    .sheet-footer {
      display: flex;
      gap: 8px;
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid var(--bw-border);
    }

    .btn {
      padding: 12px 18px;
      border-radius: 12px;
      font-size: 13px;
      font-weight: 600;
      border: none;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      outline: none;
      flex: 1;
    }

    .btn:active:not(:disabled) {
      transform: scale(0.98);
    }

    .btn-cancel {
      background: transparent;
      color: var(--bw-ink-2);
      border: 1.5px solid var(--bw-border);
    }

    .btn-cancel:hover {
      background: var(--bw-sunken);
    }

    .btn-primary {
      background: var(--bw-ink);
      color: var(--bw-on-ink);
      flex: 2;
    }

    .btn-primary:not(:disabled):hover {
      opacity: 0.92;
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .btn-primary:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  `],
  template: `
    <div class="sheet-container">
      <!-- Drag handle -->
      <div class="drag-handle"></div>

      <!-- Header -->
      <div class="sheet-header">
        <div class="header-text">
          <div class="header-eyebrow">Tambah hutang</div>
          <h2 class="header-title">
            kepada <span class="friend-name">{{ data.friendName }}</span>
          </h2>
        </div>
        <button class="close-btn" (click)="bottomSheetRef.dismiss()">
          <svg lucideX class="w-3.5 h-3.5"></svg>
        </button>
      </div>

      <!-- Body -->
      <div class="sheet-body">
        <app-add-debt-form [friendName]="data.friendName" #formComponent></app-add-debt-form>
      </div>

      <!-- Footer -->
      <div class="sheet-footer">
        <button type="button" class="btn btn-cancel" (click)="bottomSheetRef.dismiss()">
          Batal
        </button>
        <button
          type="button"
          class="btn btn-primary"
          [disabled]="!canSubmit() || submitting()"
          (click)="submit()"
          [title]="'Atau tekan Cmd+Enter'">
          <svg lucideCheck class="w-4 h-4"></svg>
          {{ submitting() ? 'Menyimpan...' : 'Simpan' }}
        </button>
      </div>

      <!-- Keyboard hints (mobile) -->
      <div style="margin-top: 12px; padding-top: 12px; border-top: 1px solid var(--bw-border); font-size: 11px; color: var(--bw-ink-3); text-align: center;">
        <div>Ketik angka untuk nominal • Backspace untuk hapus</div>
        <div style="margin-top: 4px;">← → ganti arah • <span style="display: inline-block; padding: 2px 4px; background: var(--bw-elevated); border-radius: 3px; font-family: monospace;">⌘ ↵</span> simpan • Esc tutup</div>
      </div>
    </div>
  `,
})
export class AddDebtSheetComponent {
  @ViewChild(AddDebtFormComponent) form!: AddDebtFormComponent;

  private debtService = inject(DebtService);
  private snackBar = inject(MatSnackBar);
  submitting = signal(false);

  canSubmit = () => this.form?.amount() > 0;

  constructor(
    public bottomSheetRef: MatBottomSheetRef<AddDebtSheetComponent>,
    @Inject(MAT_BOTTOM_SHEET_DATA) public data: AddDebtSheetData,
  ) {}

  @HostListener('window:keydown', ['$event'])
  onKeyDown(event: KeyboardEvent) {
    // Cmd+Enter (Mac) or Ctrl+Enter (Windows) to submit
    if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
      event.preventDefault();
      if (this.canSubmit()) {
        this.submit();
      }
    }

    // Escape to close
    if (event.key === 'Escape') {
      this.bottomSheetRef.dismiss();
    }
  }

  async submit() {
    if (!this.form || this.form.amount() === 0) {
      this.snackBar.open('Masukkan nominal terlebih dahulu', 'Tutup', { duration: 2000 });
      return;
    }

    if (this.form.direction() === 'debt') {
      this.snackBar.open('Fitur "aku hutang ke dia" masih dalam pengembangan.', 'Tutup', { duration: 3000 });
      return;
    }

    this.submitting.set(true);
    try {
      await this.debtService.createDebt(
        this.form.amount(),
        this.form.description(),
        this.data.friendId,
      );
      this.snackBar.open(`Hutang berhasil dicatat ke ${this.data.friendName}`, 'Tutup', { duration: 2500 });
      this.bottomSheetRef.dismiss('success');
    } catch {
      this.snackBar.open('Gagal menyimpan hutang. Coba lagi.', 'Tutup', { duration: 3000 });
    } finally {
      this.submitting.set(false);
    }
  }
}
