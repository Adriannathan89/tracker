import { Component, EventEmitter, Input, Output } from "@angular/core";
import { Friend } from "../../../core/service/friend/friend.service";

@Component({
    selector: 'app-friend-list-item',
    standalone: true,
    imports: [],
    template: `
        <div class="flex items-center justify-between p-4 rounded-[var(--bw-r-lg)] border border-bw-border bg-bw-surface">
            <div class="flex items-center gap-3">
                <span class="w-10 h-10 rounded-full bg-bw-sunken text-bw-ink flex items-center justify-center text-[14px] font-bold shrink-0">
                    {{ friend.username.slice(0,1).toUpperCase() }}
                </span>
                <div>
                    <p class="font-semibold text-bw-ink text-[14px]">{{ friend.username }}</p>
                    <p class="text-[12px] text-bw-ink-3">Teman</p>
                </div>
            </div>
            <button
                class="px-3 py-1.5 rounded-[var(--bw-r-md)] text-[12px] font-semibold cursor-pointer border border-bw-border text-bw-ink-2 hover:border-bw-ink hover:text-bw-ink transition-colors"
                (click)="addDebt.emit(friend)">
                + Tambah Hutang
            </button>
        </div>
    `
})
export class FriendListItemComponent {
    @Input({ required: true }) friend!: Friend;
    @Output() addDebt = new EventEmitter<Friend>();
}
