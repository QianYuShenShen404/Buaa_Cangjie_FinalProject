document.addEventListener('DOMContentLoaded', function () {
    const selectedToolInput = document.getElementById('selectedToolInput');

    // 默认选中 generateCodeSignature 按钮
    const defaultButton = document.getElementById('generateCodeSignature');


    if (defaultButton) {
        // 移除所有 active 类
        document.querySelectorAll('.tool-button').forEach(btn => btn.classList.remove('active'));

        // 添加 active 到默认按钮
        defaultButton.classList.add('active');

        // 设置隐藏字段并切换表单字段
        const tool = defaultButton.getAttribute('data-tool');
        selectedToolInput.value = tool;

        toggleFormFields(tool);
    }

    // 绑定点击事件到每个按钮
    const buttons = document.querySelectorAll('.tool-button');
    buttons.forEach(button => {
        button.addEventListener('click', function () {
            // 移除所有 active 类
            buttons.forEach(btn => btn.classList.remove('active'));

            // 添加 active 到当前按钮
            this.classList.add('active');

            // 更新隐藏字段并切换表单字段
            const tool = this.getAttribute('data-tool');
            selectedToolInput.value = tool;
            toggleFormFields(tool);
        });
    });
});


// 修改 toggleFormFields 函数以接受参数
function toggleFormFields(tool) {
    document.querySelectorAll('.form-group').forEach(el => {
        el.classList.remove('visible');
    });

    if (tool && toolConfig[tool]) {
        toolConfig[tool].forEach(id => {
            document.getElementById(id).classList.add('visible');
        });
    }
}

// 工具字段可见性配置
const toolConfig = {
    generateCodeSignature: ['signatureExplain', 'codeGroup'],
    refactorVariable: ['refactorExplain', 'codeGroup', 'refactorFields'],
    generateDocument: ['documentExplain', 'codeGroup', 'documentFields'],
    foldConstant: ['foldExplain', 'codeGroup']
};
// 提交表单
async function submitForm() {
    const tool = document.getElementById('selectedToolInput').value;
    const code = document.getElementById('code').value;
    const resultElement = document.getElementById('result');

    // 构建请求数据
    let requestData = { tool, code };

    // 收集工具特定参数
    switch (tool) {
        case 'refactorVariable':
            requestData.path = document.getElementById('path_ref').value;
            requestData.oldName = document.getElementById('oldName').value;
            requestData.newName = document.getElementById('newName').value;
            break;
        case 'generateDocument':
            requestData.path = document.getElementById('path_gen').value;
            break;
    }

    try {
        const response = await fetch('http://127.0.0.1:8080/process', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams(requestData).toString()
        });

        if (response.headers.get('content-type')?.includes('application/json')) {
            const data = await response.json();
            if (data.status === 'success') {
                resultElement.textContent = data.result;
                resultElement.style.color = '#333';
            } else {
                resultElement.textContent = `错误：${data.message}`;
                resultElement.style.color = 'black';
            }
        } else {
            const text = await response.text();
            resultElement.textContent = text;
            resultElement.style.color = 'black';
        }
    } catch (error) {
        resultElement.textContent = `请求失败：${error.message}`;
        resultElement.style.color = 'black';
    }
}