import SwiftUI

struct PublicBookingView: View {
    let linkId: String
    let onBack: () -> Void

    @State private var page: BookingPage?
    @State private var isLoading = true
    @State private var selectedDate: String = ""
    @State private var selectedTime: String = ""
    @State private var name = ""
    @State private var dni = ""
    @State private var phone = ""
    @State private var isSubmitting = false
    @State private var success = false
    @State private var error = ""

    private var availableSlots: [String] {
        guard let page else { return [] }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let dayOfWeek = dayName(from: selectedDate)
        guard let day = page.schedule[dayOfWeek], day.enabled else { return [] }

        let booked = Set(page.bookedSlots
            .filter { $0.date == selectedDate && $0.status != "cancelled" }
            .map { $0.time })

        return day.slots.filter { !booked.contains($0) }
    }

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.white)
            } else if success {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.success)
                    Text("¡Turno reservado!")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Te esperamos el \(selectedDate) a las \(selectedTime)")
                        .foregroundColor(AppColors.textSecondary)
                    Button("Volver") { onBack() }
                        .foregroundColor(AppColors.primary)
                        .padding(.top)
                }
            } else if let page {
                ScrollView {
                    VStack(spacing: 20) {
                        Text(page.service.name)
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        // Date picker
                        DatePicker("Fecha", selection: Binding(
                            get: {
                                let fmt = DateFormatter()
                                fmt.dateFormat = "yyyy-MM-dd"
                                return fmt.date(from: selectedDate) ?? .now
                            },
                            set: { date in
                                let fmt = DateFormatter()
                                fmt.dateFormat = "yyyy-MM-dd"
                                selectedDate = fmt.string(from: date)
                                selectedTime = ""
                            }
                        ), in: Date()..., displayedComponents: .date)
                        .tint(AppColors.primary)
                        .foregroundColor(.white)

                        // Time slots
                        if !selectedDate.isEmpty {
                            if availableSlots.isEmpty {
                                Text("No hay horarios disponibles")
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                                    ForEach(availableSlots, id: \.self) { slot in
                                        Button {
                                            selectedTime = slot
                                        } label: {
                                            Text(slot)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundColor(selectedTime == slot ? .white : AppColors.textSecondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(selectedTime == slot ? AppColors.primary : Color.white.opacity(0.06))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                }
                            }
                        }

                        // Client form
                        if !selectedTime.isEmpty {
                            VStack(spacing: 12) {
                                InputField(icon: "person", placeholder: "Nombre completo", text: $name)
                                InputField(icon: "person.text.rectangle", placeholder: "DNI", text: $dni, keyboardType: .numberPad)
                                InputField(icon: "phone", placeholder: "Celular", text: $phone, keyboardType: .phonePad)
                            }

                            if !error.isEmpty {
                                Text(error).font(.caption).foregroundColor(AppColors.destructive)
                            }

                            Button {
                                Task { await submit() }
                            } label: {
                                HStack {
                                    if isSubmitting { ProgressView().tint(.white) }
                                    else { Text("Reservar turno") }
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            }
                            .background(AppColors.primaryGradient)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .disabled(isSubmitting)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    private func dayName(from dateStr: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: dateStr) else { return "" }
        let weekday = Calendar.current.component(.weekday, from: date)
        let names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        return names[weekday - 1]
    }

    private func submit() async {
        guard !name.isEmpty, !dni.isEmpty, !phone.isEmpty else {
            error = "Completá todos los campos"
            return
        }
        isSubmitting = true
        do {
            _ = try await APIService.shared.createBooking(
                linkId: linkId,
                payload: BookingPayload(name: name, dni: dni, phone: phone, date: selectedDate, time: selectedTime)
            )
            success = true
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}
