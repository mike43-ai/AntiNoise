import PhotosUI
import SwiftUI

struct CaptureImagePickerView: View {
    @Binding var image: UIImage?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            preview

            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: image == nil ? "photo" : "arrow.triangle.2.circlepath")
                    Text(image == nil ? "Pick from library" : "Replace")
                        .appFont(.bodySmall)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, AppSpacing.lg)
                .frame(minHeight: 44)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
            .onChange(of: selectedItem) { _, newValue in
                Task { await load(item: newValue) }
            }
        }
    }

    @ViewBuilder private var preview: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(Color.surface)
                .frame(height: 200)
                .overlay(
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "photo")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(Color.textMuted)
                        Text("No image yet")
                            .appFont(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        }
    }

    private func load(item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let ui = UIImage(data: data) {
            image = ui
        }
    }
}

private struct CaptureImagePickerViewPreview: View {
    @State private var image: UIImage?

    var body: some View {
        CaptureImagePickerView(image: $image)
            .padding()
            .background(Color.bgPrimary)
    }
}

#Preview {
    CaptureImagePickerViewPreview()
}
