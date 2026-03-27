"use client";

import { useState, useMemo, useEffect } from "react";
import {
  useReactTable,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  flexRender,
  type ColumnDef,
  type SortingState,
  type RowSelectionState,
  type VisibilityState,
} from "@tanstack/react-table";
import {
  Search,
  ChevronLeft,
  ChevronRight,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Download,
  Columns3,
  X,
} from "lucide-react";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { cn } from "@/lib/utils";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuCheckboxItem,
} from "@/components/ui/dropdown-menu";

export interface BulkAction<T> {
  label: string;
  icon?: React.ReactNode;
  onClick: (rows: T[]) => void | Promise<void>;
  destructive?: boolean;
}

export interface ExportColumn<T> {
  header: string;
  accessor: (row: T) => string | number | boolean | undefined | null;
}

interface DataTableProps<T> {
  columns: ColumnDef<T, unknown>[];
  data: T[];
  searchKey?: string;
  searchPlaceholder?: string;
  filterTabs?: { label: string; filter: (row: T) => boolean }[];
  onRowClick?: (row: T) => void;
  // Row selection & bulk actions
  enableRowSelection?: boolean;
  bulkActions?: BulkAction<T>[];
  // Export CSV
  exportFilename?: string;
  exportColumns?: ExportColumn<T>[];
  // Column visibility toggle
  enableColumnVisibility?: boolean;
  // Advanced filter bar slot (rendered below search row)
  filterBar?: React.ReactNode;
}

function exportToCsv<T>(
  data: T[],
  columns: ExportColumn<T>[],
  filename: string,
) {
  const headers = columns.map((c) => `"${c.header}"`).join(",");
  const rows = data.map((row) =>
    columns
      .map((c) => {
        const val = c.accessor(row);
        if (val === null || val === undefined) return '""';
        return `"${String(val).replace(/"/g, '""')}"`;
      })
      .join(","),
  );
  const csv = [headers, ...rows].join("\n");
  // BOM prefix for Excel UTF-8 compatibility
  const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${filename}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

export function DataTable<T>({
  columns,
  data,
  searchPlaceholder = "Buscar...",
  filterTabs,
  onRowClick,
  enableRowSelection = false,
  bulkActions,
  exportFilename,
  exportColumns,
  enableColumnVisibility = false,
  filterBar,
}: DataTableProps<T>) {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [globalFilter, setGlobalFilter] = useState("");
  const [activeTab, setActiveTab] = useState(0);
  const [rowSelection, setRowSelection] = useState<RowSelectionState>({});
  const [columnVisibility, setColumnVisibility] = useState<VisibilityState>({});

  // Reset row selection when tab changes
  useEffect(() => { setRowSelection({}); }, [activeTab]);

  const filteredData = useMemo(() => {
    if (filterTabs && activeTab > 0) {
      return data.filter(filterTabs[activeTab].filter);
    }
    return data;
  }, [data, filterTabs, activeTab]);

  // Prepend selection column when enabled
  const allColumns = useMemo<ColumnDef<T, unknown>[]>(() => {
    if (!enableRowSelection) return columns;
    const selectionCol: ColumnDef<T, unknown> = {
      id: "__select__",
      enableSorting: false,
      size: 40,
      header: ({ table }) => (
        <input
          type="checkbox"
          checked={table.getIsAllPageRowsSelected()}
          ref={(el) => {
            if (el) el.indeterminate = table.getIsSomePageRowsSelected() && !table.getIsAllPageRowsSelected();
          }}
          onChange={table.getToggleAllPageRowsSelectedHandler()}
          className="h-4 w-4 cursor-pointer rounded"
          style={{ accentColor: "var(--color-primary)" }}
          onClick={(e) => e.stopPropagation()}
        />
      ),
      cell: ({ row }) => (
        <input
          type="checkbox"
          checked={row.getIsSelected()}
          disabled={!row.getCanSelect()}
          onChange={row.getToggleSelectedHandler()}
          className="h-4 w-4 cursor-pointer rounded"
          style={{ accentColor: "var(--color-primary)" }}
          onClick={(e) => e.stopPropagation()}
        />
      ),
    };
    return [selectionCol, ...columns];
  }, [columns, enableRowSelection]);

  const table = useReactTable({
    data: filteredData,
    columns: allColumns,
    state: { sorting, globalFilter, rowSelection, columnVisibility },
    onSortingChange: setSorting,
    onGlobalFilterChange: setGlobalFilter,
    onRowSelectionChange: setRowSelection,
    onColumnVisibilityChange: setColumnVisibility,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    globalFilterFn: "includesString",
    initialState: { pagination: { pageSize: 10 } },
    // Use Firestore document id for stable selection across pagination
    getRowId: (row, index) => {
      const id = (row as Record<string, unknown>).id;
      return typeof id === "string" ? id : String(index);
    },
  });

  const selectedRows = table.getSelectedRowModel().rows.map((r) => r.original);
  const selectedCount = selectedRows.length;
  const hasBulkActions = enableRowSelection && (bulkActions?.length ?? 0) > 0;

  function handleExport() {
    if (!exportColumns || !exportFilename) return;
    const exportData =
      selectedCount > 0
        ? selectedRows
        : table.getFilteredRowModel().rows.map((r) => r.original);
    exportToCsv(exportData, exportColumns, exportFilename);
  }

  // Columns that can be toggled (exclude selection and actions columns)
  const toggleableColumns = table
    .getAllColumns()
    .filter((col) => col.id !== "__select__" && col.id !== "actions" && col.getCanHide());

  return (
    <div className="space-y-3">
      {/* Search + Filter Tabs + Actions Row */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[180px] max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            value={globalFilter}
            onChange={(e) => setGlobalFilter(e.target.value)}
            placeholder={searchPlaceholder}
            className="h-9 w-full rounded-lg border border-border bg-transparent pl-9 pr-3 text-sm outline-none transition-all duration-200 placeholder:text-muted-foreground focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </div>
        {filterTabs && (
          <div className="flex gap-1">
            {filterTabs.map((tab, i) => (
              <button
                key={tab.label}
                onClick={() => setActiveTab(i)}
                className={cn(
                  "rounded-full px-3.5 py-1 text-xs font-medium transition-all",
                  activeTab === i
                    ? "bg-primary text-primary-foreground"
                    : "border border-border text-muted-foreground hover:text-foreground hover:border-[var(--border-hover)]",
                )}
              >
                {tab.label}
              </button>
            ))}
          </div>
        )}

        {/* Right-side utility buttons */}
        <div className="flex items-center gap-2 ml-auto">
          {exportColumns && exportFilename && (
            <button
              onClick={handleExport}
              title={selectedCount > 0 ? `Exportar ${selectedCount} selecionado(s)` : "Exportar todos (CSV)"}
              className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-muted-foreground transition-all hover:border-primary/50 hover:text-primary hover:bg-primary/5"
            >
              <Download className="h-3.5 w-3.5" />
              {selectedCount > 0 ? `Exportar (${selectedCount})` : "Exportar CSV"}
            </button>
          )}

          {enableColumnVisibility && toggleableColumns.length > 0 && (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <button className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-muted-foreground transition-all hover:border-primary/50 hover:text-primary hover:bg-primary/5">
                  <Columns3 className="h-3.5 w-3.5" />
                  Colunas
                </button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-44">
                {toggleableColumns.map((col) => (
                  <DropdownMenuCheckboxItem
                    key={col.id}
                    checked={col.getIsVisible()}
                    onCheckedChange={(val) => col.toggleVisibility(val)}
                  >
                    {typeof col.columnDef.header === "string" ? col.columnDef.header : col.id}
                  </DropdownMenuCheckboxItem>
                ))}
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </div>
      </div>

      {/* Advanced filter bar slot */}
      {filterBar && <div className="flex items-center gap-2 flex-wrap">{filterBar}</div>}

      {/* Bulk action toolbar — animated slide in/out */}
      {hasBulkActions && (
        <div
          className={cn(
            "overflow-hidden transition-all duration-300 ease-out",
            selectedCount > 0 ? "max-h-14 opacity-100" : "max-h-0 opacity-0",
          )}
        >
          <div className="flex items-center gap-3 rounded-xl border border-primary/30 bg-primary/5 px-4 py-2.5">
            <span className="text-sm font-medium text-primary shrink-0">
              {selectedCount} {selectedCount === 1 ? "item selecionado" : "itens selecionados"}
            </span>
            <div className="flex items-center gap-2">
              {bulkActions?.map((action) => (
                <button
                  key={action.label}
                  onClick={() => action.onClick(selectedRows)}
                  className={cn(
                    "flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-medium transition-all",
                    action.destructive
                      ? "border border-destructive/40 text-destructive hover:bg-destructive/10"
                      : "border border-border bg-background text-foreground hover:bg-accent",
                  )}
                >
                  {action.icon}
                  {action.label}
                </button>
              ))}
            </div>
            <button
              onClick={() => setRowSelection({})}
              className="ml-auto flex items-center justify-center rounded-md p-1 text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
              title="Limpar seleção"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="rounded-xl border border-border bg-card overflow-hidden">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <TableHead
                    key={header.id}
                    onClick={header.column.getCanSort() ? header.column.getToggleSortingHandler() : undefined}
                    className={header.column.getCanSort() ? "cursor-pointer select-none" : ""}
                    style={header.column.getSize() !== 150 ? { width: header.column.getSize() } : undefined}
                  >
                    {header.isPlaceholder ? null : (
                      <div className="flex items-center gap-1">
                        {flexRender(header.column.columnDef.header, header.getContext())}
                        {header.column.getCanSort() && (
                          <span className="ml-0.5">
                            {header.column.getIsSorted() === "asc" ? (
                              <ArrowUp className="h-3.5 w-3.5 text-primary" />
                            ) : header.column.getIsSorted() === "desc" ? (
                              <ArrowDown className="h-3.5 w-3.5 text-primary" />
                            ) : (
                              <ArrowUpDown className="h-3.5 w-3.5 text-muted-foreground/50" />
                            )}
                          </span>
                        )}
                      </div>
                    )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows.length === 0 ? (
              <TableRow>
                <TableCell colSpan={allColumns.length} className="h-32">
                  <div className="flex flex-col items-center justify-center gap-1 py-4">
                    <Search className="h-8 w-8 text-muted-foreground/30 mb-1" />
                    <span className="text-sm font-medium text-muted-foreground">Nenhum resultado encontrado</span>
                    <span className="text-xs text-muted-foreground/60">Tente buscar com outros termos</span>
                  </div>
                </TableCell>
              </TableRow>
            ) : (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  data-state={row.getIsSelected() ? "selected" : undefined}
                  className={cn(
                    onRowClick ? "cursor-pointer" : "",
                    row.getIsSelected() && "bg-primary/5",
                  )}
                  onClick={(e) => {
                    const target = e.target as HTMLElement;
                    if (
                      target.closest(
                        "button, a, [role=menuitem], [data-radix-collection-item], input[type=checkbox]",
                      )
                    )
                      return;
                    onRowClick?.(row.original);
                  }}
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>

        {/* Pagination */}
        {table.getFilteredRowModel().rows.length > 0 && (
          <div className="flex items-center justify-between border-t border-border px-4 py-3 text-sm text-muted-foreground">
            <span>
              Mostrando {table.getState().pagination.pageIndex * table.getState().pagination.pageSize + 1}–
              {Math.min(
                (table.getState().pagination.pageIndex + 1) * table.getState().pagination.pageSize,
                table.getFilteredRowModel().rows.length,
              )}{" "}
              de {table.getFilteredRowModel().rows.length}
              {selectedCount > 0 && (
                <span className="ml-2 font-medium text-primary">
                  · {selectedCount} selecionado{selectedCount > 1 ? "s" : ""}
                </span>
              )}
            </span>
            <div className="flex gap-1">
              <button
                onClick={() => table.previousPage()}
                disabled={!table.getCanPreviousPage()}
                className="flex h-8 w-8 items-center justify-center rounded-md border border-border text-sm disabled:opacity-30 hover:bg-accent transition-colors"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              {(() => {
                const pageCount = table.getPageCount();
                const currentPage = table.getState().pagination.pageIndex;
                const maxVisible = 5;
                let start = Math.max(0, currentPage - Math.floor(maxVisible / 2));
                const end = Math.min(pageCount, start + maxVisible);
                start = Math.max(0, end - maxVisible);
                return (
                  <>
                    {start > 0 && (
                      <>
                        <button
                          onClick={() => table.setPageIndex(0)}
                          className="flex h-8 w-8 items-center justify-center rounded-md border border-border text-sm hover:bg-accent transition-colors"
                        >
                          1
                        </button>
                        {start > 1 && (
                          <span className="flex h-8 w-8 items-center justify-center text-xs">…</span>
                        )}
                      </>
                    )}
                    {Array.from({ length: end - start }, (_, i) => {
                      const page = start + i;
                      return (
                        <button
                          key={page}
                          onClick={() => table.setPageIndex(page)}
                          className={cn(
                            "flex h-8 w-8 items-center justify-center rounded-md border text-sm transition-colors",
                            currentPage === page
                              ? "border-primary bg-primary text-primary-foreground"
                              : "border-border hover:bg-accent",
                          )}
                        >
                          {page + 1}
                        </button>
                      );
                    })}
                    {end < pageCount && (
                      <>
                        {end < pageCount - 1 && (
                          <span className="flex h-8 w-8 items-center justify-center text-xs">…</span>
                        )}
                        <button
                          onClick={() => table.setPageIndex(pageCount - 1)}
                          className="flex h-8 w-8 items-center justify-center rounded-md border border-border text-sm hover:bg-accent transition-colors"
                        >
                          {pageCount}
                        </button>
                      </>
                    )}
                  </>
                );
              })()}
              <button
                onClick={() => table.nextPage()}
                disabled={!table.getCanNextPage()}
                className="flex h-8 w-8 items-center justify-center rounded-md border border-border text-sm disabled:opacity-30 hover:bg-accent transition-colors"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
