import { Component, ElementRef, EventEmitter, HostListener, Input, Output, signal } from '@angular/core';

export type Period = { month: number; year: number } | null;

@Component({
  selector: 'app-transaction-period-filter',
  standalone: true,
  imports: [],
  styleUrls: ['./transaction-ui.styles.css'],
  template: `
    <div class="relative">
      <button
        class="filter-chip flex items-center gap-1.5"
        [class.active]="activePeriod !== null"
        (click)="toggleOpen($event)">
        {{ activeLabel() }}
        <svg width="12" height="12" viewBox="0 0 12 12" fill="none" style="margin-top:1px">
          <path d="M2 4l4 4 4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </button>

      @if (isOpen()) {
        <div class="absolute top-full left-0 mt-1 z-50 min-w-[180px] rounded-[var(--bw-r-lg)] border border-bw-border bg-bw-surface shadow-[var(--bw-shadow-md)] py-1.5 animate-fade-in">
          @for (opt of options; track opt.label) {
            <button
              class="w-full text-left px-4 py-2 text-[13px] cursor-pointer hover:bg-bw-elevated transition-colors"
              [class.font-semibold]="isActive(opt.value)"
              [class.text-bw-ink]="isActive(opt.value)"
              [class.text-bw-ink-2]="!isActive(opt.value)"
              (click)="selectOption(opt.value)">
              {{ opt.label }}
            </button>
          }
        </div>
      }
    </div>
  `,
})
export class TransactionPeriodFilterComponent {
  @Input() activePeriod: Period = null;
  @Output() selectPeriod = new EventEmitter<Period>();

  isOpen = signal(false);
  readonly options: Array<{ label: string; value: Period }>;

  constructor(private el: ElementRef) {
    const now = new Date();
    this.options = [{ label: 'Semua waktu', value: null }];
    for (let i = 0; i < 12; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      this.options.push({
        label: new Intl.DateTimeFormat('id-ID', { month: 'long', year: 'numeric' }).format(d),
        value: { month: d.getMonth(), year: d.getFullYear() }
      });
    }
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent) {
    if (!this.el.nativeElement.contains(event.target)) {
      this.isOpen.set(false);
    }
  }

  toggleOpen(event: MouseEvent) {
    event.stopPropagation();
    this.isOpen.update(v => !v);
  }

  selectOption(value: Period) {
    this.selectPeriod.emit(value);
    this.isOpen.set(false);
  }

  isActive(value: Period): boolean {
    if (value === null && this.activePeriod === null) return true;
    if (value === null || this.activePeriod === null) return false;
    return value.month === this.activePeriod.month && value.year === this.activePeriod.year;
  }

  activeLabel(): string {
    if (!this.activePeriod) return 'Semua waktu';
    const d = new Date(this.activePeriod.year, this.activePeriod.month, 1);
    return new Intl.DateTimeFormat('id-ID', { month: 'long', year: 'numeric' }).format(d);
  }

}
