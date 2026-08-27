import SwiftUI

struct AgendaView: View {
    @State private var bookings: [Booking] = []
    @State private var isLoading = true
    @State private var selectedDate = Date()
    @State private var filterStatus: String? = nil

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: selectedDate)
    }

    private var filteredBookings: [Booking] {
        bookings.sorted { $0.time < $1.time }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Agenda")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        Task { await load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                // Date picker
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(AppColors.primary)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Status filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "Todos", isSelected: filterStatus == nil) {
                            filterStatus = nil
                            Task { await load() }
                        }
                        FilterChip(label: "Pendientes", isSelected: filterStatus == "pending") {
                            filterStatus = "pending"
                            Task { await load() }
                        }
                        FilterChip(label: "Completados", isSelected: filterStatus == "completed") {
                            filterStatus = "completed"
                            Task { await load() }
                        }
                        FilterChip(label: "Cancelados", isSelected: filterStatus == "cancelled") {
                            filterStatus = "cancelled"
                            Task { await load() }
                        }
                    }
                }

                // Bookings list
                if isLoading {
                    ProgressView().tint(.white).padding(.top, 40)
                } else if filteredBookings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)
                        Text("No hay turnos para esta fecha")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(filteredBookings) { booking in
                        BookingCard(booking: booking) { newStatus in
                            Task { await updateStatus(booking: booking, status: newStatus) }
                        }
                    }
                }
            }
            .padding(20)
        }
        .task { await load() }
        .onChange(of: selectedDate) { _, _ in
            Task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        do {
            bookings = try await APIService.shared.listBookings(
                date: dateString,
                status: filterStatus
            )
        } catch {}
        isLoading = false
    }

    private func updateStatus(booking: Booking, status: String) async {
        do {
            _ = try await APIService.shared.updateBookingStatus(id: booking.id, status: status)
            await load()
        } catch {}
    }
}

struct BookingCard: View {
    let booking: Booking
    let onStatusChange: (String) -> Void

    private var statusColor: Color {
        switch booking.status {
        case .pending: return AppColors.warning
        case .completed: return AppColors.success
        case .cancelled: return AppColors.destructive
        }
    }

    private var statusLabel: String {
        switch booking.status {
        case .pending: return "Pendiente"
        case .completed: return "Completado"
        case .cancelled: return "Cancelado"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.clientName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(booking.serviceName)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Text(booking.time)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundColor(AppColors.primary)
            }

            HStack(spacing: 16) {
                Label(booking.clientPhone, systemImage: "phone")
                Label(booking.clientDNI, systemImage: "person.text.rectangle")
            }
            .font(.caption)
            .foregroundColor(AppColors.textSecondary)

            HStack {
                Text(statusLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                if booking.status == .pending {
                    Button {
                        onStatusChange("completed")
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                            .font(.title3)
                    }
                    Button {
                        onStatusChange("cancelled")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.destructive)
                            .font(.title3)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
    }
}
