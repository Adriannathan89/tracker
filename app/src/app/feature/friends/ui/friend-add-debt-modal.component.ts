import { Component, Inject, signal, computed } from "@angular/core";
import { FormBuilder, ReactiveFormsModule, Validators } from "@angular/forms";
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from "@angular/material/dialog";
import { MatSnackBar } from "@angular/material/snack-bar";
import { DebtService } from "../../../core/service/debt/debt.service";

export type AddDebtDialogData = {
    friendId: string;
    friendUsername: string;
};

@Component({
    selector: 'app-friend-add-debt-modal',
    standalone: true,
    imports: [ReactiveFormsModule, MatDialogModule],
    styles: [`
        :host {
            display: block;
        }

        .modal-container {
            animation: modal-pop-in 0.35s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
            backdrop-filter: blur(0px);
        }

        @keyframes modal-pop-in {
            0% {
                opacity: 0;
                transform: scale(0.90) translateY(-12px);
            }
            100% {
                opacity: 1;
                transform: scale(1) translateY(0);
            }
        }

        .modal-header {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
            margin-bottom: 1.5rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid var(--bw-border);
        }

        .modal-title {
            font-size: 18px;
            font-weight: 700;
            color: var(--bw-ink-2);
            margin: 0;
        }

        .modal-subtitle {
            font-size: 13px;
            color: var(--bw-ink-3);
        }

        .modal-subtitle .username {
            font-weight: 600;
            color: var(--bw-ink-2);
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
        }

        .form-label {
            font-size: 12px;
            font-weight: 600;
            color: var(--bw-ink-2);
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
        }

        .form-input {
            width: 100%;
            padding: 0.75rem 1rem;
            border-radius: 8px;
            border: 1.5px solid var(--bw-border);
            background-color: var(--bw-elevated);
            color: var(--bw-ink);
            font-size: 14px;
            outline: none;
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
            font-weight: 500;
        }

        .form-input::placeholder {
            color: var(--bw-ink-3);
        }

        .form-input:hover:not(:focus) {
            border-color: var(--bw-ink-2);
            background-color: var(--bw-surface);
        }

        .form-input:focus {
            border-color: var(--bw-ink);
            background-color: var(--bw-surface);
            box-shadow: 0 0 0 3px rgba(var(--bw-ink-rgb, 0 0 0), 0.08);
        }

        .error-text {
            font-size: 12px;
            color: var(--bw-red);
            display: flex;
            align-items: center;
            gap: 0.5rem;
            animation: error-slide 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        }

        @keyframes error-slide {
            from {
                opacity: 0;
                transform: translateY(-4px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .form-actions {
            display: flex;
            gap: 0.75rem;
            justify-content: flex-end;
            margin-top: 1.5rem;
            padding-top: 1rem;
            border-top: 1px solid var(--bw-border);
        }

        .btn {
            padding: 0.625rem 1.25rem;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            border: none;
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
            outline: none;
        }

        .btn-cancel {
            border: 1.5px solid var(--bw-border);
            color: var(--bw-ink-2);
            background-color: transparent;
        }

        .btn-cancel:hover {
            background-color: var(--bw-sunken);
            border-color: var(--bw-ink-2);
        }

        .btn-cancel:active {
            transform: scale(0.98);
        }

        .btn-submit {
            background-color: var(--bw-ink);
            color: var(--bw-on-ink);
        }

        .btn-submit:not(:disabled) {
            cursor: pointer;
        }

        .btn-submit:not(:disabled):hover {
            opacity: 0.92;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }

        .btn-submit:not(:disabled):active {
            transform: translateY(0);
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
        }

        .btn-submit:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
    `],
    template: `
        <div class="modal-container w-[420px] p-6 bg-bw-surface rounded-2xl shadow-lg">
            <div class="modal-header">
                <h2 class="modal-title">Tambah Hutang</h2>
                <p class="modal-subtitle">kepada <span class="username">{{ data.friendUsername }}</span></p>
            </div>

            <form [formGroup]="form" (ngSubmit)="submit()" class="flex flex-col gap-5">
                <!-- Nominal Input -->
                <div class="form-group">
                    <label class="form-label">Nominal (Rp)</label>
                    <div class="input-wrapper">
                        <input
                            type="text"
                            inputmode="numeric"
                            [value]="formattedAmount()"
                            (input)="handleAmountInput($event)"
                            placeholder="Masukkan nominal..."
                            class="form-input"
                        />
                    </div>
                    @if (rawAmount() === 0 && amountTouched) {
                        <p class="error-text">
                            ⚠ Nominal harus lebih dari 0
                        </p>
                    }
                </div>

                <!-- Description Input -->
                <div class="form-group">
                    <label class="form-label">Deskripsi</label>
                    <div class="input-wrapper">
                        <input
                            type="text"
                            formControlName="description"
                            placeholder="Misal: Makan malam bersama"
                            class="form-input"
                        />
                    </div>
                    @if (form.controls.description.invalid && form.controls.description.touched) {
                        <p class="error-text">
                            ⚠ Deskripsi wajib diisi
                        </p>
                    }
                </div>

                <!-- Actions -->
                <div class="form-actions">
                    <button
                        type="button"
                        class="btn btn-cancel"
                        (click)="dialogRef.close()">
                        Batal
                    </button>
                    <button
                        type="submit"
                        [disabled]="!canSubmit || submitting"
                        class="btn btn-submit">
                        {{ submitting ? 'Menyimpan...' : 'Simpan Hutang' }}
                    </button>
                </div>
            </form>
        </div>
    `
})
export class FriendAddDebtModalComponent {
    rawAmount = signal(0);
    amountTouched = false;
    submitting = false;
    form;

    formattedAmount = computed(() => {
        const v = this.rawAmount();
        return v === 0 ? '' : new Intl.NumberFormat('id-ID').format(v);
    });

    get canSubmit() {
        return this.rawAmount() > 0 && this.form.controls.description.valid;
    }

    constructor(
        public dialogRef: MatDialogRef<FriendAddDebtModalComponent>,
        @Inject(MAT_DIALOG_DATA) public data: AddDebtDialogData,
        private fb: FormBuilder,
        private debtService: DebtService,
        private snackBar: MatSnackBar
    ) {
        this.form = this.fb.nonNullable.group({
            description: ['', [Validators.required]],
        });
    }

    handleAmountInput(e: Event) {
        this.amountTouched = true;
        const raw = (e.target as HTMLInputElement).value.replace(/\D/g, '');
        this.rawAmount.set(raw ? Math.min(Number(raw), 999_999_999) : 0);
    }

    async submit() {
        this.amountTouched = true;
        if (!this.canSubmit) return;
        this.submitting = true;
        try {
            const { description } = this.form.getRawValue();
            await this.debtService.createDebt(this.rawAmount(), description, this.data.friendId);
            this.snackBar.open('Hutang berhasil ditambahkan.', 'Tutup', { duration: 3000 });
            this.dialogRef.close('success');
        } catch {
            this.snackBar.open('Gagal menambahkan hutang.', 'Tutup', { duration: 3000 });
            this.submitting = false;
        }
    }
}
