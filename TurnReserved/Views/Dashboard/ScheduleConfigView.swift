import SwiftUI

struct ScheduleConfigView: View {
    let service: Service
    @Environment(\.dismiss) private var dismiss
    @State private var schedule: ServiceSchedule = [:]
    @State private var dayConfig: DayConfigMap = [:]
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var saved = false

    private let days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    private let dayLabels = [
        "monday": "Lunes", "tuesday": "Martes", "wednesday": "Miércoles",
        "thursday": "Jueves", "friday": "Viernes", "saturday": "Sábado", "sunday": "Domingo"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(days, id: \.self) { day in
                                DayScheduleCard(
                                    dayName: dayLabels[day] ?? day,
                                    enabled: schedule[day]?.enabled ?? false,
                                    startTime: dayConfig[day]?.startTime ?? "09:00",
                                    endTime: dayConfig[day]?.endTime ?? "18:00",
                                    duration: dayConfig[day]?.duration ?? 30,
                                    onToggle: { enabled in
                                        schedule[day] = DaySchedule(enabled: enabled, slots: schedule[day]?.slots ?? [])
                                    },
                                    onStartChange: { time in
                                        let old = dayConfig[day] ?? DayConfig(startTime: "09:00", endTime: "18:00", duration: 30)
                                        dayConfig[day] = DayConfig(startTime: time, endTime: old.endTime, duration: old.duration)
                                    },
                                    onEndChange: { time in
                                        let old = dayConfig[day] ?? DayConfig(startTime: "09:00", endTime: "18:00", duration: 30)
                                        dayConfig[day] = DayConfig(startTime: old.startTime, endTime: time, duration: old.duration)
                                    },
                                    onDurationChange: { dur in
                                        let old = dayConfig[day] ?? DayConfig(startTime: "09:00", endTime: "18:00", duration: 30)
                                        dayConfig[day] = DayConfig(startTime: old.startTime, endTime: old.endTime, duration: dur)
                                    }
                                )
                            }

                            Button {
                                Task { await save() }
                            } label: {
                                HStack {
                                    if isSaving {
                                        ProgressView().tint(.white)
                                    } else if saved {
                                        Label("Guardado", systemImage: "checkmark")
                                    } else {
                                        Text("Guardar horarios")
                                    }
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            }
                            .background(saved ? AppColors.success : AppColors.primary)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .disabled(isSaving)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Horarios: \(service.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let res = try await APIService.shared.getSchedule(serviceId: service.id)
            schedule = res.schedule
            dayConfig = res.dayConfig
        } catch {
            // Initialize defaults
            for day in days {
                schedule[day] = DaySchedule(enabled: false, slots: [])
                dayConfig[day] = DayConfig(startTime: "09:00", endTime: "18:00", duration: 30)
            }
        }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await APIService.shared.saveSchedule(serviceId: service.id, schedule: schedule, dayConfig: dayConfig)
            saved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
        } catch {}
    }
}

struct DayScheduleCard: View {
    let dayName: String
    var enabled: Bool
    let startTime: String
    let endTime: String
    let duration: Int
    let onToggle: (Bool) -> Void
    let onStartChange: (String) -> Void
    let onEndChange: (String) -> Void
    let onDurationChange: (Int) -> Void

    private let durations = [15, 20, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dayName)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { enabled },
                    set: { onToggle($0) }
                ))
                .tint(AppColors.primary)
            }

            if enabled {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Inicio").font(.caption).foregroundColor(AppColors.textSecondary)
                        TimePickerField(time: startTime, onChange: onStartChange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fin").font(.caption).foregroundColor(AppColors.textSecondary)
                        TimePickerField(time: endTime, onChange: onEndChange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duración").font(.caption).foregroundColor(AppColors.textSecondary)
                        Menu {
                            ForEach(durations, id: \.self) { d in
                                Button("\(d) min") { onDurationChange(d) }
                            }
                        } label: {
                            Text("\(duration) min")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

struct TimePickerField: View {
    let time: String
    let onChange: (String) -> Void

    private var date: Binding<Date> {
        Binding(
            get: {
                let parts = time.split(separator: ":").compactMap { Int($0) }
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
                comps.hour = parts.first ?? 9
                comps.minute = parts.count > 1 ? parts[1] : 0
                return Calendar.current.date(from: comps) ?? .now
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                let h = String(format: "%02d", comps.hour ?? 0)
                let m = String(format: "%02d", comps.minute ?? 0)
                onChange("\(h):\(m)")
            }
        )
    }

    var body: some View {
        DatePicker("", selection: date, displayedComponents: .hourAndMinute)
            .labelsHidden()
            .tint(AppColors.primary)
    }
}
