<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;

class OrdersByStatusChart extends ChartWidget
{
    protected static ?int $sort = 3;

    protected ?string $heading = 'Orders by status';

    protected function getType(): string
    {
        return 'doughnut';
    }

    protected function getData(): array
    {
        $counts = Order::selectRaw('status, COUNT(*) as total')->groupBy('status')->pluck('total', 'status');
        $colors = [
            'pending' => '#f59e0b',
            'confirmed' => '#3b82f6',
            'delivering' => '#8b5cf6',
            'delivered' => '#22c55e',
            'cancelled' => '#ef4444',
        ];

        $labels = [];
        $data = [];
        $bg = [];
        foreach (Order::STATUSES as $key => $label) {
            $labels[] = $label;
            $data[] = (int) ($counts[$key] ?? 0);
            $bg[] = $colors[$key];
        }

        return [
            'datasets' => [['data' => $data, 'backgroundColor' => $bg]],
            'labels' => $labels,
        ];
    }
}
