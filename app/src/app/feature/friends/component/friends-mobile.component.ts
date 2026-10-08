import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Friend } from '../../../core/service/friend/friend.service';
import { FriendRequest } from '../../../core/service/friend/friend-request.service';
import { Debt } from '../../../core/model/debt.model';
import { FriendWithBalance } from '../friends.page';

@Component({
  selector: 'app-friends-mobile',
  standalone: true,
  imports: [],
  template: `
    <div class="flex flex-col gap-4 lg:hidden px-5 pb-20 pt-4">

      <!-- Header + search -->
      <div class="flex flex-col gap-3">
        <h1 class="text-[20px] font-bold text-bw-ink">Teman</h1>
        <input
          type="text"
          [value]="searchQuery"
          (input)="searchChange.emit($any($event.target).value)"
          placeholder="Cari teman..."
          class="w-full px-4 py-2.5 rounded-[var(--bw-r-md)] border border-bw-border bg-bw-elevated text-bw-ink text-[14px] outline-none focus:border-bw-ink transition-colors"
        />
      </div>

      <!-- Pending requests card -->
      @if (pendingRequests.length > 0) {
        <div class="rounded-[var(--bw-r-lg)] bg-bw-lime-soft p-4 flex flex-col gap-3">
          <p class="text-[13px] font-bold text-bw-lime-ink">
            {{ pendingRequests.length }} Permintaan Pertemanan
          </p>
          @for (req of pendingRequests; track req.id) {
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <span class="w-7 h-7 rounded-full bg-bw-ink text-bw-on-ink flex items-center justify-center text-[11px] font-bold">
                  {{ req.senderUsername.slice(0,1).toUpperCase() }}
                </span>
                <span class="text-[13px] font-semibold text-bw-lime-ink">{{ req.senderUsername }}</span>
              </div>
              <div class="flex gap-2">
                <button (click)="accept.emit(req.id)"
                  class="px-2.5 py-1 rounded-[var(--bw-r-sm)] text-[11px] font-semibold cursor-pointer bg-bw-ink text-bw-on-ink">
                  Terima
                </button>
                <button (click)="reject.emit(req.id)"
                  class="px-2.5 py-1 rounded-[var(--bw-r-sm)] text-[11px] font-semibold cursor-pointer border border-bw-border text-bw-ink-2">
                  Tolak
                </button>
              </div>
            </div>
          }
        </div>
      }

      <!-- Net balance card -->
      <div class="rounded-[var(--bw-r-lg)] bg-bw-ink text-bw-on-ink p-4">
        <p class="text-[12px] opacity-60 mb-1">Saldo Bersih</p>
        <p class="text-[22px] font-bold"
          [class.text-bw-green]="netBalance >= 0"
          [class.text-bw-red]="netBalance < 0">
          {{ netBalance >= 0 ? '+' : '' }}{{ formatRupiah(netBalance) }}
        </p>
        <div class="flex gap-6 mt-3">
          <div>
            <p class="text-[11px] opacity-50">Piutang</p>
            <p class="text-[13px] font-semibold text-bw-green">{{ formatRupiah(totalOwedToMe) }}</p>
          </div>
          <div>
            <p class="text-[11px] opacity-50">Hutang</p>
            <p class="text-[13px] font-semibold text-bw-red">{{ formatRupiah(totalIOwe) }}</p>
          </div>
        </div>
      </div>

      <!-- Friend list -->
      @if (filteredFriends.length === 0) {
        <div class="flex flex-col items-center justify-center py-12 text-bw-ink-3">
          <p class="text-[14px]">Belum ada teman</p>
        </div>
      } @else {
        <div class="flex flex-col gap-2">
          @for (fw of filteredFriends; track fw.friend.id) {
            <div class="flex items-center justify-between px-4 py-3 rounded-[var(--bw-r-md)] border border-bw-border bg-bw-surface">
              <div class="flex items-center gap-3">
                <span class="w-9 h-9 rounded-full bg-bw-sunken text-bw-ink flex items-center justify-center text-[13px] font-bold shrink-0">
                  {{ fw.friend.username.slice(0,1).toUpperCase() }}
                </span>
                <div>
                  <p class="text-[14px] font-semibold text-bw-ink">{{ fw.friend.username }}</p>
                  <p class="text-[12px]"
                    [class.text-bw-green]="fw.balance >= 0"
                    [class.text-bw-red]="fw.balance < 0">
                    {{ fw.balance >= 0 ? '+' : '' }}{{ formatRupiah(fw.balance) }}
                  </p>
                </div>
              </div>
              <div class="flex gap-2 shrink-0">
                @if (fw.iOwe > 0) {
                  <button
                    (click)="onBayar(fw)"
                    class="px-3 py-1.5 rounded-[var(--bw-r-sm)] text-[12px] font-semibold cursor-pointer border border-bw-border text-bw-red hover:bg-bw-red-soft transition-colors">
                    Bayar
                  </button>
                }
                <button
                  (click)="addDebt.emit(fw.friend)"
                  class="px-3 py-1.5 rounded-[var(--bw-r-sm)] text-[12px] font-semibold cursor-pointer border border-bw-border text-bw-ink-2 hover:border-bw-ink transition-colors">
                  + Hutang
                </button>
              </div>
            </div>
          }
        </div>
      }

    </div>
  `,
})
export class FriendsMobileComponent {
  private snackBar = inject(MatSnackBar);

  @Input() filteredFriends: FriendWithBalance[] = [];
  @Input() pendingRequests: FriendRequest[] = [];
  @Input() owedDebts: Debt[] = [];
  @Input() searchQuery = '';
  @Input() totalOwedToMe = 0;
  @Input() totalIOwe = 0;
  @Input() netBalance = 0;

  @Output() searchChange = new EventEmitter<string>();
  @Output() accept = new EventEmitter<string>();
  @Output() reject = new EventEmitter<string>();
  @Output() payDebt = new EventEmitter<string>();
  @Output() addDebt = new EventEmitter<Friend>();

  formatRupiah = (n: number) => 'Rp ' + Math.abs(n).toLocaleString('id-ID');

  onBayar(fw: FriendWithBalance) {
    const debt = this.owedDebts.find(d => d.ownerId === fw.friend.id);
    if (!debt) {
      this.snackBar.open('Tidak ada hutang yang harus dibayar.', 'Tutup', { duration: 3000 });
      return;
    }
    this.payDebt.emit(debt.id);
  }
}
