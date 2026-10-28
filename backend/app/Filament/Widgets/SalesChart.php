<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;

class SalesChart extends ChartWidget
{
    protected static ?int $sort = 2;

    protected ?string $heading = 'Sales - last 14 days';

    protected int|string|array $columnSpan = 'full';

    protected function getType(): string
    {
        return 'line';
    }

    protected function getData(): array
    {
        $start = now()->subDays(13)->startOfDay();

        $totals = Order::where('status', '!=', 'cancelled')
            ->where('created_at', '>=', $start)
            ->get()
            ->groupBy(fn (Order $o) => $o->created_at->format('Y-m-d'))
            ->map->sum('total');

        $labels = [];
        $data = [];
        for ($i = 0; $i < 14; $i++) {
            $day = $start->copy()->addDays($i);
            $labels[] = $day->format('d M');
            $data[] = round((float) ($totals[$day->format('Y-m-d')] ?? 0), 2);
        }

        return [
            'datasets' => [[
                'label' => 'Revenue ($)',
                'data' => $data,
                'borderColor' => '#f59e0b',
                'backgroundColor' => 'rgba(245, 158, 11, 0.15)',
                'fill' => true,
                'tension' => 0.35,
            ]],
            'labels' => $labels,
        ];
    }
}
