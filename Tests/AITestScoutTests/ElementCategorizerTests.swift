import Testing
import XCTest
@testable import AITestScout

@Suite("ElementCategorizer Tests")
struct ElementCategorizerTests {

    @Test("Should categorize button as 'button'")
    func testButtonCategorization() {
        // Act
        let category = ElementCategorizer.categorize(.button)

        // Assert
        #expect(category.type == "button")
        #expect(category.interactive == true)
    }

    @Test("Should categorize text field as 'input'")
    func testTextFieldCategorization() {
        // Act
        let category = ElementCategorizer.categorize(.textField)

        // Assert
        #expect(category.type == "input")
        #expect(category.interactive == true)
    }

    @Test("Should categorize secure text field as 'input'")
    func testSecureTextFieldCategorization() {
        // Act
        let category = ElementCategorizer.categorize(.secureTextField)

        // Assert
        #expect(category.type == "input")
        #expect(category.interactive == true)
    }

    @Test("Should categorize static text as 'text'")
    func testStaticTextCategorization() {
        // Act
        let category = ElementCategorizer.categorize(.staticText)

        // Assert
        #expect(category.type == "text")
        #expect(category.interactive == false)
    }

    @Test("Should categorize image as 'image'")
    func testImageCategorization() {
        // Act
        let category = ElementCategorizer.categorize(.image)

        // Assert
        #expect(category.type == "image")
        #expect(category.interactive == false)
    }

    @Test("Should categorize scroll view as 'scrollable'")
    func testScrollViewCategorization() {
        // Act
        let category = ElementCategorizer.categorize(.scrollView)

        // Assert
        #expect(category.type == "scrollable")
        #expect(category.interactive == true)
    }

    @Test("Should categorize table as 'scrollable'")
    func testTableCategorization() {
        // Act
        let category = ElementCategorizer.categorize(.table)

        // Assert
        #expect(category.type == "scrollable")
        #expect(category.interactive == true)
    }

    @Test("Should categorize link as 'link'")
    func testLinkCategorization() {
        // Act
        let category = ElementCategorizer.categorize(.link)

        // Assert
        #expect(category.type == "link")
        #expect(category.interactive == true)
    }

    @Test("Should categorize switch/toggle as 'toggle'")
    func testToggleCategorization() {
        // Act
        let switchCategory = ElementCategorizer.categorize(.switch)
        let toggleCategory = ElementCategorizer.categorize(.toggle)

        // Assert
        #expect(switchCategory.type == "toggle")
        #expect(switchCategory.interactive == true)
        #expect(toggleCategory.type == "toggle")
        #expect(toggleCategory.interactive == true)
    }

    @Test("Should skip system UI elements")
    func testSystemUISkipping() {
        // Act & Assert
        #expect(ElementCategorizer.shouldSkip(.menuBar) == true)
        #expect(ElementCategorizer.shouldSkip(.menuBarItem) == true)
        #expect(ElementCategorizer.shouldSkip(.statusBar) == true)
        #expect(ElementCategorizer.shouldSkip(.touchBar) == true)
    }

    @Test("Should not skip content elements")
    func testContentElementsNotSkipped() {
        // Act & Assert
        #expect(ElementCategorizer.shouldSkip(.button) == false)
        #expect(ElementCategorizer.shouldSkip(.textField) == false)
        #expect(ElementCategorizer.shouldSkip(.staticText) == false)
        #expect(ElementCategorizer.shouldSkip(.scrollView) == false)
    }

    @Test("Should categorize groups and containers as 'container'")
    func testContainerCategorization() {
        // Act
        let groupCategory = ElementCategorizer.categorize(.group)
        let otherCategory = ElementCategorizer.categorize(.other)

        // Assert
        #expect(groupCategory.type == "container")
        #expect(groupCategory.interactive == false)
        #expect(otherCategory.type == "container")
        #expect(otherCategory.interactive == false)
    }

    @Test("Should skip keyboard elements")
    func testKeyboardSkipping() {
        // Act & Assert - keyboard elements should be skipped
        #expect(ElementCategorizer.shouldSkip(.keyboard) == true)
        #expect(ElementCategorizer.shouldSkip(.key) == true)
    }

    @Test("Should not skip non-keyboard interactive elements")
    func testNonKeyboardInteractiveElementsNotSkipped() {
        // Act & Assert - ensure we don't accidentally skip app UI
        #expect(ElementCategorizer.shouldSkip(.button) == false)
        #expect(ElementCategorizer.shouldSkip(.textField) == false)
        #expect(ElementCategorizer.shouldSkip(.secureTextField) == false)
        #expect(ElementCategorizer.shouldSkip(.link) == false)
        #expect(ElementCategorizer.shouldSkip(.toggle) == false)
    }

    // MARK: - Picker Element Tests

    @Test("Should categorize pickers as 'picker'")
    func testPickerCategorization() {
        // Act
        let picker = ElementCategorizer.categorize(.picker)
        let pickerWheel = ElementCategorizer.categorize(.pickerWheel)
        let datePicker = ElementCategorizer.categorize(.datePicker)

        // Assert
        #expect(picker.type == "picker")
        #expect(picker.interactive == true)

        #expect(pickerWheel.type == "picker")
        #expect(pickerWheel.interactive == true)

        #expect(datePicker.type == "picker")
        #expect(datePicker.interactive == true)
    }

    // MARK: - Slider and Stepper Tests

    @Test("Should categorize sliders and steppers as 'slider'")
    func testSliderAndStepperCategorization() {
        // Act
        let slider = ElementCategorizer.categorize(.slider)
        let stepper = ElementCategorizer.categorize(.stepper)

        // Assert
        #expect(slider.type == "slider")
        #expect(slider.interactive == true)

        #expect(stepper.type == "slider")
        #expect(stepper.interactive == true)
    }

    // MARK: - Tab Element Tests

    @Test("Should categorize tab elements as 'tab'")
    func testTabElementCategorization() {
        // Act
        let tab = ElementCategorizer.categorize(.tab)
        let tabBar = ElementCategorizer.categorize(.tabBar)
        let tabGroup = ElementCategorizer.categorize(.tabGroup)
        let segmentedControl = ElementCategorizer.categorize(.segmentedControl)

        // Assert
        #expect(tab.type == "tab")
        #expect(tab.interactive == true)

        #expect(tabBar.type == "tab")
        #expect(tabBar.interactive == true)

        #expect(tabGroup.type == "tab")
        #expect(tabGroup.interactive == true)

        #expect(segmentedControl.type == "tab")
        #expect(segmentedControl.interactive == true)
    }

    // MARK: - Additional Interactive Elements

    @Test("Should categorize various button types as 'button'")
    func testVariousButtonTypes() {
        // Act
        let radioButton = ElementCategorizer.categorize(.radioButton)
        let checkBox = ElementCategorizer.categorize(.checkBox)
        let menuButton = ElementCategorizer.categorize(.menuButton)
        let toolbarButton = ElementCategorizer.categorize(.toolbarButton)
        let popUpButton = ElementCategorizer.categorize(.popUpButton)

        // Assert
        #expect(radioButton.type == "button")
        #expect(radioButton.interactive == true)

        #expect(checkBox.type == "button")
        #expect(checkBox.interactive == true)

        #expect(menuButton.type == "button")
        #expect(menuButton.interactive == true)

        #expect(toolbarButton.type == "button")
        #expect(toolbarButton.interactive == true)

        #expect(popUpButton.type == "button")
        #expect(popUpButton.interactive == true)
    }

    @Test("Should categorize search field as 'input'")
    func testSearchFieldCategorization() {
        // Act
        let searchField = ElementCategorizer.categorize(.searchField)

        // Assert
        #expect(searchField.type == "input")
        #expect(searchField.interactive == true)
    }

    @Test("Should categorize various scrollable elements")
    func testScrollableElementCategorization() {
        // Act
        let collectionView = ElementCategorizer.categorize(.collectionView)
        let outline = ElementCategorizer.categorize(.outline)

        // Assert
        #expect(collectionView.type == "scrollable")
        #expect(collectionView.interactive == true)

        #expect(outline.type == "scrollable")
        #expect(outline.interactive == true)
    }

    // MARK: - Container and Layout Elements

    @Test("Should categorize layout elements as non-interactive containers")
    func testLayoutElementCategorization() {
        // Act
        let layoutArea = ElementCategorizer.categorize(.layoutArea)
        let layoutItem = ElementCategorizer.categorize(.layoutItem)
        let splitGroup = ElementCategorizer.categorize(.splitGroup)
        let cell = ElementCategorizer.categorize(.cell)

        // Assert
        #expect(layoutArea.type == "container")
        #expect(layoutArea.interactive == false)

        #expect(layoutItem.type == "container")
        #expect(layoutItem.interactive == false)

        #expect(splitGroup.type == "container")
        #expect(splitGroup.interactive == false)

        #expect(cell.type == "container")
        #expect(cell.interactive == false)
    }

    @Test("Should categorize icon as 'image'")
    func testIconCategorization() {
        // Act
        let icon = ElementCategorizer.categorize(.icon)

        // Assert
        #expect(icon.type == "image")
        #expect(icon.interactive == false)
    }

    // MARK: - System UI Comprehensive Tests

    @Test("Should skip all system UI elements")
    func testAllSystemUISkipping() {
        // Act & Assert
        let systemElements: [XCUIElement.ElementType] = [
            .menuBar, .menuBarItem, .menu, .menuItem,
            .statusBar, .statusItem, .touchBar, .toolbar
        ]

        for elementType in systemElements {
            #expect(
                ElementCategorizer.shouldSkip(elementType) == true,
                "\(elementType) should be skipped as system UI"
            )
        }
    }

    @Test("Should categorize system UI elements consistently")
    func testSystemUIConsistentCategorization() {
        // Even though these are skipped, they should have consistent categorization

        let application = ElementCategorizer.categorize(.application)
        let window = ElementCategorizer.categorize(.window)
        let navigationBar = ElementCategorizer.categorize(.navigationBar)

        #expect(application.type == "system")
        #expect(application.interactive == false)

        #expect(window.type == "system")
        #expect(window.interactive == false)

        #expect(navigationBar.type == "system")
        #expect(navigationBar.interactive == false)
    }
}
