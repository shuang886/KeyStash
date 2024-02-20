import SwiftUI
import MarkdownUI
import AlertToast

struct LicenceInfo: View {
	@EnvironmentObject var databaseManager: DatabaseManager
	@EnvironmentObject var viewModes: ViewModes
	@EnvironmentObject var formState: EditFormState
	var license: License
	
	@State private var showToast: Bool = false
	
	@AppStorage("disableAnimations") private var disableAnimations: Bool = false
	
	var body: some View {
		ScrollView {
			VStack {
				ZStack {
					Rectangle()
						.fill(.regularMaterial)
					HStack {
						Image(nsImage: license.iconNSImage)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 75)
						VStack(alignment: .leading) {
							if viewModes.editMode == true {
								TextField("Some Cool App", text: $formState.softwareName)
									.textFieldStyle(RoundedBorderTextFieldStyle())
								TextField("https://sampleapp.com/download", text: $formState.urlString)
									.textFieldStyle(RoundedBorderTextFieldStyle())
							} else {
								Text(license.softwareName)
									.font(.title)
									.multilineTextAlignment(.leading)
								if let url = license.downloadUrl {
									Link(destination: url, label: {
										if isDownloadLink(url: url) {
											Label("Download", systemImage: "arrow.down.circle")
										} else {
											Label("Website", systemImage: "safari")
										}
									})
									.buttonStyle(.borderedProminent)
								}
							}
						}
						Spacer()
					}
					.padding()
				}
				VStack(alignment: .leading, spacing: 12) {
					
					LicenseInfoRow(
						showToast: $showToast,
						value: license.registeredToName,
						formValue: $formState.registeredToName,
						label: "Registered To"
					)
					
					LicenseInfoRow(
						showToast: $showToast,
						value: license.registeredToEmail,
						formValue: $formState.registeredToEmail,
						label: "Email"
					)
					
					LicenseInfoRow(
						showToast: $showToast,
						value: license.licenseKey,
						formValue: $formState.licenseKey,
						label: "License Key")
					
					AttachmentRow(license: license)
					Divider()
					Text("Notes")
						.font(.caption)
					if viewModes.editMode == true {
						TextEditor(text: $formState.notes)
							.frame(minHeight: 100)
					} else {
						Markdown(license.notes)
					}
				}
				.frame(maxWidth: .infinity)
				.padding()
			}
			.animation(disableAnimations == false ? .easeIn : nil, value: viewModes.editMode)
		}
		.frame(maxWidth: .infinity)
		.environmentObject(formState)
		.toast(isPresenting: $showToast){
			AlertToast(type: .regular, title: "Copied to Clipboard")
		}
		.toolbar {
			ToolbarItem {
				Spacer()
			}
			if viewModes.editMode == true {
				ToolbarItem {
					Button(action: {
						saveFormState()
						viewModes.editMode.toggle()
					}, label: {
						Image(systemName: "checkmark.circle")
					})
					.disabled(!isEdited())
					.keyboardShortcut(KeyEquivalent("s"))
					.help("Save")
				}
			}
			ToolbarItem {
				Button(action: {
					if viewModes.editMode == false {
						initFormState()
					}
					viewModes.editMode.toggle()
				}, label: {
					Image(systemName: viewModes.editMode == true ? "xmark.circle" : "square.and.pencil")
				})
				.help(viewModes.editMode == true ? "Cancel" : "Edit")
			}
		}
	}
	
	private func initFormState() {
		formState.softwareName = license.softwareName
		formState.urlString = license.downloadUrlString
		formState.registeredToName = license.registeredToName
		formState.registeredToEmail = license.registeredToEmail
		formState.licenseKey = license.licenseKey
		formState.notes = license.notes
	}
	
	private func saveFormState() {
		do {
			var updatedLicense = license
			updatedLicense.softwareName = formState.softwareName
			updatedLicense.downloadUrlString = formState.urlString
			updatedLicense.registeredToName = formState.registeredToName
			updatedLicense.registeredToEmail = formState.registeredToEmail
			updatedLicense.licenseKey = formState.licenseKey
			updatedLicense.notes = formState.notes
			try updateLicense(databaseManager.dbQueue, data: updatedLicense)
			databaseManager.fetchData()
		} catch {
			logger.error("ERROR: \(error)")
		}
	}
	
	private func isEdited() -> Bool {
		if formState.softwareName == license.softwareName &&
				formState.urlString == license.downloadUrlString &&
				formState.registeredToName == license.registeredToName &&
				formState.registeredToEmail == license.registeredToEmail &&
				formState.licenseKey == license.licenseKey &&
				formState.notes == license.notes {
			return false
		}
		
		return true
	}
}
