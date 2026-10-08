import { Component, EventEmitter, Input, Output, signal, inject } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Friend } from '../../../core/service/friend/friend.service';
import { FriendRequest } from '../../../core/service/friend/friend-request.service';
import { Debt } from '../../../core/model/debt.model';
import { FriendWithBalance } from '../friends.page';

@Component({
  selector: 'app-friends-desktop',
  standalone: true,
  imports: [],
  template: `
    <div class="hidden lg:grid p-8 gap-6 min-h-full" style="grid-template-columns: 1fr 360px;">

      <!-- Left column -->
      <div class="flex flex-col gap-5 min-w-0">

        <!-- Search -->
        <input
          type="text"
          [value]="searchQuery"
          (input)="searchChange.emit($any($event.target).value)"
          placeholder="Cari teman..."
          class="w-full px-4 py-2.5 rounded-[var(--bw-r-md)] border border-bw-border bg-bw-elevated text-bw-ink text-[14px] outline-none focus:border-bw-ink transition-colors"
        />

        <!-- Tabs -->
        <div class="flex gap-1 p-1 rounded-[var(--bw-r-md)] bg-bw-sunken">
          <button
            (click)="tabChange.emit('friends')"
            class="flex-1 py-2 rounded-[var(--bw-r-sm)] text-[13px] font-semibold transition-colors cursor-pointer"
            [class.bg-bw-surface]="activeTab === 'friends'"
            [class.text-bw-ink]="activeTab === 'friends'"
            [class.text-bw-ink-3]="activeTab !== 'friends'"
          >
            Teman
          </button>
          <button
            (click)="tabChange.emit('requests')"
            class="flex-1 py-2 rounded-[var(--bw-r-sm)] text-[13px] font-semibold transition-colors cursor-pointer"
            [class.bg-bw-surface]="activeTab === 'requests'"
            [class.text-bw-ink]="activeTab === 'requests'"
            [class.text-bw-ink-3]="activeTab !== 'requests'"
          >
            Permintaan
            @if (pendingRequests.length > 0) {
              <span class="ml-1.5 inline-flex items-center justify-center w-4 h-4 rounded-full bg-bw-red text-white text-[10px] font-bold">
                {{ pendingRequests.length }}
              </span>
            }
          </button>
        </div>

        <!-- Requests tab -->
        @if (activeTab === 'requests') {
          @if (pendingRequests.length === 0) {
            <div class="flex flex-col items-center justify-center py-16 text-bw-ink-3">
              <p class="text-[14px]">Tidak ada permintaan pertemanan</p>
            </div>
          } @else {
            <div class="rounded-[var(--bw-r-lg)] bg-bw-lime-soft p-4 flex flex-col gap-3">
              @for (req of pendingRequests; track req.id) {
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <span class="w-8 h-8 rounded-full bg-bw-ink text-bw-on-ink flex items-center justify-center text-[12px] font-bold">
                      {{ req.senderUsername.slice(0,1).toUpperCase() }}
                    </span>
                    <span class="text-[14px] font-semibold text-bw-lime-ink">{{ req.senderUsername }}</span>
                  </div>
                  <div class="flex gap-2">
                    <button
                      (click)="accept.emit(req.id)"
                      class="px-3 py-1.5 rounded-[var(--bw-r-sm)] text-[12px] font-semibold cursor-pointer bg-bw-ink text-bw-on-ink transition-colors">
                      Terima
                    </button>
                    <button
                      (click)="reject.emit(req.id)"
                      class="px-3 py-1.5 rounded-[var(--bw-r-sm)] text-[12px] font-semibold cursor-pointer border border-bw-border text-bw-ink-2 hover:border-bw-ink transition-colors">
                      Tolak
                    </button>
                  </div>
                </div>
              }
            </div>
          }
        }

        <!-- Friends tab -->
        @if (activeTab === 'friends') {
          @if (filteredFriends.length === 0) {
            <div class="flex flex-col items-center justify-center py-16 text-bw-ink-3">
              <p class="text-[14px]">Belum ada teman</p>
            </div>
          } @else {
            <div class="flex flex-col gap-2">
              @for (fw of filteredFriends; track fw.friend.id) {
                <div class="flex items-center gap-4 px-4 py-3 rounded-[var(--bw-r-md)] border border-bw-border bg-bw-surface hover:bg-bw-elevated transition-colors">
                  <div class="flex items-center gap-3 flex-1 min-w-0">
                    <span class="w-9 h-9 rounded-full bg-bw-sunken text-bw-ink flex items-center justify-center text-[13px] font-bold shrink-0">
                      {{ fw.friend.username.slice(0,1).toUpperCase() }}
                    </span>
                    <span class="text-[14px] font-semibold text-bw-ink truncate">{{ fw.friend.username }}</span>
                  </div>
                  <div class="flex items-center gap-6 shrink-0">
                    <div class="text-right">
                      <p class="text-[11px] text-bw-ink-3">Piutang</p>
                      <p class="text-[13px] font-semibold text-bw-green">{{ formatRupiah(fw.owedToMe) }}</p>
                    </div>
                    <div class="text-right">
                      <p class="text-[11px] text-bw-ink-3">Hutang</p>
                      <p class="text-[13px] font-semibold text-bw-red">{{ formatRupiah(fw.iOwe) }}</p>
                    </div>
                  </div>
                  <div class="flex items-center gap-2 shrink-0">
                    <button
                      (click)="showComingSoon()"
                      class="px-3 py-1.5 rounded-[var(--bw-r-sm)] text-[12px] font-semibold cursor-pointer border border-bw-border text-bw-green hover:bg-bw-green-soft transition-colors">
                      Tagih
                    </button>
                    <button
                      (click)="onBayar(fw)"
                      [disabled]="fw.iOwe === 0"
                      class="px-3 py-1.5 rounded-[var(--bw-r-sm)] text-[12px] font-semibold cursor-pointer border border-bw-border text-bw-red hover:bg-bw-red-soft transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
                      Bayar
                    </button>
                    <div class="relative">
                      <button
                        (click)="toggleMenu(fw.friend.id)"
                        class="w-7 h-7 flex items-center justify-center rounded-[var(--bw-r-sm)] hover:bg-bw-sunken transition-colors cursor-pointer text-bw-ink-3 text-[16px] leading-none">
                        ···
                      </button>
                      @if (openMenuId() === fw.friend.id) {
                        <div class="absolute right-0 top-9 z-10 w-40 rounded-[var(--bw-r-md)] border border-bw-border bg-bw-surface shadow-md">
                          <button
                            (click)="addDebt.emit(fw.friend); toggleMenu(null)"
                            class="w-full px-4 py-2.5 text-left text-[13px] text-bw-ink hover:bg-bw-elevated transition-colors rounded-[var(--bw-r-md)] cursor-pointer">
                            + Tambah Hutang
                          </button>
                        </div>
                      }
                    </div>
                  </div>
                </div>
              }
            </div>
          }
        }

      </div>

      <!-- Right column -->
      <div class="flex flex-col gap-4">

        <!-- Invite card -->
        <div class="rounded-[var(--bw-r-xl)] p-6 bg-bw-ink text-bw-on-ink">
          <p class="text-[16px] font-bold mb-2">Undang Teman</p>
          <p class="text-[13px] opacity-60">Cari teman dari pencarian untuk mulai mencatat hutang bersama.</p>
        </div>

        <!-- Summary card -->
        <div class="rounded-[var(--bw-r-xl)] p-5 border border-bw-border bg-bw-surface flex flex-col gap-3">
          <p class="text-[14px] font-bold text-bw-ink">Ringkasan</p>
          <div class="flex flex-col gap-2">
            <div class="flex justify-between">
              <span class="text-[13px] text-bw-ink-3">Total Piutang</span>
              <span class="text-[13px] font-semibold text-bw-green">{{ formatRupiah(totalOwedToMe) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-[13px] text-bw-ink-3">Total Hutang</span>
              <span class="text-[13px] font-semibold text-bw-red">{{ formatRupiah(totalIOwe) }}</span>
            </div>
            <div class="border-t border-bw-border pt-2 flex justify-between">
              <span class="text-[13px] font-semibold text-bw-ink">Saldo Bersih</span>
              <span class="text-[13px] font-bold"
                [class.text-bw-green]="netBalance >= 0"
                [class.text-bw-red]="netBalance < 0">
                {{ netBalance >= 0 ? '+' : '' }}{{ formatRupiah(netBalance) }}
              </span>
            </div>
          </div>
        </div>

      </div>

    </div>
  `,
})
export class FriendsDesktopComponent {
  private snackBar = inject(MatSnackBar);

  @Input() filteredFriends: FriendWithBalance[] = [];
  @Input() pendingRequests: FriendRequest[] = [];
  @Input() owedDebts: Debt[] = [];
  @Input() searchQuery = '';
  @Input() activeTab: 'friends' | 'requests' = 'friends';
  @Input() totalOwedToMe = 0;
  @Input() totalIOwe = 0;
  @Input() netBalance = 0;

  @Output() searchChange = new EventEmitter<string>();
  @Output() tabChange = new EventEmitter<'friends' | 'requests'>();
  @Output() accept = new EventEmitter<string>();
  @Output() reject = new EventEmitter<string>();
  @Output() payDebt = new EventEmitter<string>();
  @Output() addDebt = new EventEmitter<Friend>();

  openMenuId = signal<string | null>(null);

  formatRupiah = (n: number) => 'Rp ' + Math.abs(n).toLocaleString('id-ID');

  toggleMenu(id: string | null) {
    this.openMenuId.set(this.openMenuId() === id ? null : id);
  }

  showComingSoon() {
    this.snackBar.open('Fitur segera hadir.', 'Tutup', { duration: 3000 });
  }

  onBayar(fw: FriendWithBalance) {
    const debt = this.owedDebts.find(d => d.ownerId === fw.friend.id);
    if (!debt) {
      this.snackBar.open('Tidak ada hutang yang harus dibayar.', 'Tutup', { duration: 3000 });
      return;
    }
    this.payDebt.emit(debt.id);
  }
}
